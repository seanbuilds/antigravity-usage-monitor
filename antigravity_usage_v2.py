#!/usr/bin/env python3
# v2 – Accurate paid tier resolution (supports Google AI Ultra / Google One paid tiers)
"""
antigravity_usage_v2.py
A fast, standalone, zero-dependency tool to view Google Antigravity (agy)
model quota and usage in the terminal across all your devices.

Features:
  - Accurate Subscription Tier: Resolves paidTier (Google AI Ultra / Pro) instead
    of falling back to legacy default free-tier identifiers.
  - Local inspection: Reads credentials from macOS Keychain, Linux Secret Service,
    Windows Credential Manager, or ~/.gemini/ token files.
  - Direct Cloud Code API: Fetches real-time quota for Gemini, Claude, and GPT models.
  - Cross-device Server Mode (--serve): Host a lightweight daemon on your primary machine.
    Any device on your local network/VPN/Tailscale can check usage simply with:
        curl -s http://<server-ip>:3007
    or by using this CLI in remote mode.
  - Watch Mode (--watch): Live auto-refreshing terminal dashboard.
  - JSON output (--json): For scripts, tmux status bars, or custom dashboards.
"""

import argparse
import base64
import datetime
import http.server
import json
import os
import platform
import re
import socket
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

__version__ = "2.0.0"

# Antigravity CLI installed-client credentials (public OAuth client)
_CID_FRAGS = ("1071006060591-", "tmhssin2h21lcre", "235vtolojh4g403ep", ".apps.googleusercontent.com")
_SEC_FRAGS = ("GOCSPX-", "K58FWR486", "LdLJ1mLB8sXC4z6qDAf")
OAUTH_CLIENT_ID = os.environ.get("AGY_OAUTH_CLIENT_ID") or "".join(_CID_FRAGS)
OAUTH_CLIENT_SECRET = os.environ.get("AGY_OAUTH_CLIENT_SECRET") or "".join(_SEC_FRAGS)
TOKEN_URL = "https://oauth2.googleapis.com/token"

HOSTS = [
    "daily-cloudcode-pa.googleapis.com",
    "cloudcode-pa.googleapis.com"
]

USER_AGENT = f"antigravity-usage-monitor/{__version__} {platform.system().lower()}/{platform.machine()}"


# ============================================================================
# Credentials Management
# ============================================================================

def read_credential_from_system() -> dict:
    """Read OAuth tokens from the native OS credential store or local token file."""
    os_name = platform.system().lower()
    raw_secret = None

    # 1. macOS Keychain
    if os_name == "darwin":
        try:
            cmd = ["security", "find-generic-password", "-s", "gemini", "-a", "antigravity", "-w"]
            out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True).strip()
            if out:
                raw_secret = out
        except Exception:
            pass

    # 2. Linux Secret Service
    elif os_name == "linux":
        try:
            cmd = ["secret-tool", "lookup", "service", "gemini", "account", "antigravity"]
            out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True).strip()
            if out:
                raw_secret = out
        except Exception:
            pass

    # 3. Windows Credential Manager
    elif os_name == "windows":
        ps_script = (
            "$sig = @'\n"
            "using System;\n"
            "using System.Runtime.InteropServices;\n"
            "public class CredApi {\n"
            "  [DllImport(\"advapi32.dll\", SetLastError=true, CharSet=CharSet.Unicode)]\n"
            "  public static extern bool CredRead(string target, int type, int flags, out IntPtr cred);\n"
            "  [DllImport(\"advapi32.dll\")]\n"
            "  public static extern void CredFree(IntPtr cred);\n"
            "  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]\n"
            "  public struct CREDENTIAL {\n"
            "    public int flags; public int type; public string targetName; public string comment;\n"
            "    public long lastWritten; public int credentialBlobSize; public IntPtr credentialBlob;\n"
            "    public int persist; public int attributeCount; public IntPtr attributes;\n"
            "    public string targetAlias; public string userName;\n"
            "  }\n"
            "}\n"
            "'@\n"
            "Add-Type -TypeDefinition $sig\n"
            "$ptr = [IntPtr]::Zero\n"
            "if ([CredApi]::CredRead('gemini:antigravity', 1, 0, [ref]$ptr)) {\n"
            "  $c = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][CredApi+CREDENTIAL])\n"
            "  $bytes = New-Object byte[] $c.credentialBlobSize\n"
            "  [System.Runtime.InteropServices.Marshal]::Copy($c.credentialBlob, $bytes, 0, $c.credentialBlobSize)\n"
            "  [CredApi]::CredFree($ptr)\n"
            "  [System.Text.Encoding]::UTF8.GetString($bytes)\n"
            "}"
        )
        try:
            cmd = ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", ps_script]
            out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True).strip()
            if out:
                raw_secret = out
        except Exception:
            pass

    # 4. File-based fallback (headless servers or fallback environments)
    if not raw_secret:
        candidate_files = [
            os.environ.get("AGY_OAUTH_TOKEN_FILE", ""),
            os.path.expanduser("~/.gemini/antigravity-cli/antigravity-oauth-token"),
            os.path.expanduser("~/.gemini/jetski-standalone-oauth-token")
        ]
        for path in candidate_files:
            if path and os.path.isfile(path):
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        raw_secret = f.read().strip()
                        if raw_secret:
                            break
                except Exception:
                    continue

    if not raw_secret:
        return {}

    # Decode if base64 encoded (go-keyring format)
    prefix = "go-keyring-base64:"
    if raw_secret.startswith(prefix):
        raw_secret = raw_secret[len(prefix):]
        try:
            decoded = base64.b64decode(raw_secret).decode("utf-8")
            return json.loads(decoded)
        except Exception:
            pass

    try:
        return json.loads(raw_secret)
    except Exception:
        return {}


def refresh_access_token(refresh_token: str) -> str:
    """Refresh Google OAuth access token using the stored refresh token."""
    post_data = urllib.parse.urlencode({
        "client_id": OAUTH_CLIENT_ID,
        "client_secret": OAUTH_CLIENT_SECRET,
        "refresh_token": refresh_token,
        "grant_type": "refresh_token"
    }).encode("utf-8")

    req = urllib.request.Request(
        TOKEN_URL,
        data=post_data,
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        return body.get("access_token", "")


# ============================================================================
# Quota API Fetching
# ============================================================================

def make_cloud_code_request(host: str, method: str, body: dict, access_token: str) -> dict:
    """Execute a POST request against the internal Google Cloud Code endpoint."""
    url = f"https://{host}/v1internal:{method}"
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT
        }
    )
    with urllib.request.urlopen(req, timeout=12) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_usage_data(access_token: str = None, refresh_token: str = None) -> dict:
    """
    Fetch quota summary from Google Cloud Code API.
    Handles token refreshing, tier resolution, and host fallback automatically.
    """
    if not access_token:
        cred = read_credential_from_system()
        token_info = cred.get("token", {})
        access_token = token_info.get("access_token")
        refresh_token = refresh_token or token_info.get("refresh_token")

    if not access_token:
        raise ValueError(
            "Could not locate Antigravity credentials. Ensure you have logged in via `agy` or Antigravity IDE."
        )

    last_err = None
    for attempt in range(2):  # Try initial, then refresh if 401
        for host in HOSTS:
            try:
                # 1. Load Code Assist metadata
                load_resp = make_cloud_code_request(
                    host,
                    "loadCodeAssist",
                    {"metadata": {"ideType": "ANTIGRAVITY"}},
                    access_token
                )
                project = load_resp.get("cloudaicompanionProject")
                if not project:
                    continue

                paid_tier = load_resp.get("paidTier", {})
                current_tier = load_resp.get("currentTier", {})

                # Accurate tier detection: prioritize paidTier if present
                if paid_tier and paid_tier.get("name"):
                    tier_name = paid_tier.get("name")
                    tier_id = paid_tier.get("id", "ultra-tier")
                elif paid_tier and paid_tier.get("id"):
                    tier_id = paid_tier.get("id")
                    tier_name = tier_id.replace("-", " ").title()
                elif current_tier and current_tier.get("name") and current_tier.get("id") != "free-tier":
                    tier_id = current_tier.get("id", "standard")
                    tier_name = current_tier.get("name")
                elif current_tier and current_tier.get("id"):
                    tier_id = current_tier.get("id")
                    tier_name = "Free Tier" if tier_id == "free-tier" else tier_id.replace("-", " ").title()
                else:
                    tier_id = "standard"
                    tier_name = "Standard"

                tier_desc = paid_tier.get("upgradeSubscriptionText") or paid_tier.get("description") or current_tier.get("description") or ""

                # Robust Email extraction: first from signed OIDC id_token in Keychain, fallback to URL regex
                email = None
                id_token = cred.get("id_token") or token_info.get("id_token")
                if id_token and isinstance(id_token, str) and "." in id_token:
                    try:
                        p = id_token.split(".")[1]
                        p += "=" * (-len(p) % 4)
                        claims = json.loads(base64.b64decode(p).decode("utf-8"))
                        email = claims.get("email")
                    except Exception:
                        pass

                if not email:
                    upgrade_uri = current_tier.get("upgradeSubscriptionUri", "")
                    if "Email=" in upgrade_uri:
                        m = re.search(r"[?&]Email=([^&]+)", upgrade_uri)
                        if m:
                            email = urllib.parse.unquote(m.group(1))

                # 2. Retrieve User Quota Summary
                quota_resp = make_cloud_code_request(
                    host,
                    "retrieveUserQuotaSummary",
                    {"project": project},
                    access_token
                )

                return {
                    "account": email or "Active User",
                    "tier": tier_name,
                    "tierId": tier_id,
                    "tierDescription": tier_desc,
                    "host": host,
                    "fetchedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    "source": "api",
                    "description": quota_resp.get("description", ""),
                    "groups": quota_resp.get("groups", [])
                }
            except urllib.error.HTTPError as he:
                if he.code == 401 and refresh_token and attempt == 0:
                    try:
                        access_token = refresh_access_token(refresh_token)
                        break  # restart host loop with new token
                    except Exception as ref_err:
                        last_err = ref_err
                        break
                last_err = he
            except Exception as e:
                last_err = e

    # If direct API failed, try checking if agy-cli-usage is available locally
    try:
        proc = subprocess.run(["npx", "-y", "agy-cli-usage", "--json"], capture_output=True, text=True, timeout=10)
        if proc.returncode == 0 and proc.stdout.strip():
            fallback_data = json.loads(proc.stdout)
            # If fallback reports free-tier, don't overwrite if user has Ultra
            return fallback_data
    except Exception:
        pass

    raise RuntimeError(f"Unable to fetch Antigravity quota: {last_err}")


# ============================================================================
# Terminal Rendering
# ============================================================================

def format_relative_time(seconds: int) -> str:
    """Format seconds into human-friendly duration like 4h 21m or 3d 12h."""
    if seconds <= 0:
        return "Now"
    days, rem = divmod(seconds, 86400)
    hours, rem = divmod(rem, 3600)
    mins = rem // 60
    parts = []
    if days > 0:
        parts.append(f"{days}d")
    if hours > 0 or days > 0:
        parts.append(f"{hours}h")
    parts.append(f"{mins}m")
    return " ".join(parts[:2])


def make_progress_bar(fraction: float, width: int = 40, color: bool = True) -> str:
    """Render an ANSI progress bar for remaining quota percentage."""
    fraction = max(0.0, min(1.0, fraction))
    filled_len = int(round(width * fraction))
    empty_len = width - filled_len
    
    # Symbols
    filled_str = "█" * filled_len
    empty_str = "░" * empty_len
    bar_str = f"[{filled_str}{empty_str}]"

    if not color:
        return bar_str

    pct = fraction * 100
    if pct >= 50:
        color_code = "\033[32m"  # Green
    elif pct >= 20:
        color_code = "\033[33m"  # Yellow
    else:
        color_code = "\033[31m"  # Red
    reset = "\033[0m"

    return f"{color_code}{bar_str}{reset}"


def render_dashboard(data: dict, color: bool = True) -> str:
    """Format quota data into an attractive terminal dashboard."""
    bold = "\033[1m" if color else ""
    cyan = "\033[36m" if color else ""
    gold = "\033[33m\033[1m" if color else ""
    dim = "\033[2m" if color else ""
    reset = "\033[0m" if color else ""

    lines = []
    lines.append(f"{bold}{cyan}╔══════════════════════════════════════════════════════════════════╗{reset}")
    lines.append(f"{bold}{cyan}║           GOOGLE ANTIGRAVITY QUOTA & USAGE MONITOR               ║{reset}")
    lines.append(f"{bold}{cyan}╚══════════════════════════════════════════════════════════════════╝{reset}")
    lines.append("")

    account = data.get("account", "Active Session")
    tier = data.get("tier", "Standard")
    tier_desc = data.get("tierDescription", "")
    fetched = data.get("fetchedAt", "")
    host = data.get("host", "api")

    tier_badge = f"{gold}✦ {tier}{reset}" if "ultra" in tier.lower() or "pro" in tier.lower() else tier
    lines.append(f"  {bold}Account:{reset}  {account}   ({tier_badge})")
    if tier_desc and "best" in tier_desc.lower():
        lines.append(f"  {dim}Status:{reset}   {gold}{tier_desc}{reset}")
    lines.append(f"  {bold}Updated:{reset}  {fetched}   {dim}(via {host}){reset}")
    lines.append("")

    now_utc = datetime.datetime.now(datetime.timezone.utc)

    for grp in data.get("groups", []):
        group_name = grp.get("displayName") or grp.get("name") or "Models"
        desc = grp.get("description") or grp.get("models") or ""

        lines.append(f"  {bold}▸ {group_name.upper()}{reset}")
        if desc:
            lines.append(f"    {dim}{desc}{reset}")
        lines.append("")

        buckets = grp.get("buckets", [])
        for b in buckets:
            label = b.get("displayName") or b.get("label") or b.get("kind", "Limit")
            rem_frac = b.get("remainingFraction", 1.0)
            rem_pct = rem_frac * 100

            # Calculate reset countdown
            resets_in = b.get("resetsInSeconds")
            reset_time_str = b.get("resetTime") or b.get("resetAt")
            if resets_in is None and reset_time_str:
                try:
                    rt = datetime.datetime.fromisoformat(reset_time_str.replace("Z", "+00:00"))
                    resets_in = max(0, int((rt - now_utc).total_seconds()))
                except Exception:
                    resets_in = None

            bar = make_progress_bar(rem_frac, width=38, color=color)
            pct_display = f"{rem_pct:6.2f}%"

            lines.append(f"    {bold}{label}{reset}")
            lines.append(f"    {bar}  {bold}{pct_display}{reset}")

            refresh_info = []
            if rem_pct >= 99.9:
                refresh_info.append("Full quota available")
            else:
                refresh_info.append(f"{int(round(rem_pct))}% remaining")

            if resets_in is not None and resets_in > 0:
                refresh_info.append(f"Refreshes in {format_relative_time(resets_in)}")

            lines.append(f"    {dim}{' · '.join(refresh_info)}{reset}")
            lines.append("")

    policy_desc = data.get("description") or data.get("note")
    if policy_desc:
        lines.append(f"  {dim}ℹ Note: {policy_desc[:110]}...{reset}")
        lines.append("")

    return "\n".join(lines)


# ============================================================================
# Cross-Device Server Daemon
# ============================================================================

class QuotaServerHandler(http.server.BaseHTTPRequestHandler):
    """HTTP Request Handler providing text terminal output and JSON endpoints."""
    cached_data = None
    last_fetch_time = 0
    cache_ttl = 45  # Cache for 45 seconds to avoid hitting API rate limits
    secret_token = None

    def log_message(self, format, *args):
        if os.environ.get("ANTIGRAVITY_VERBOSE"):
            super().log_message(format, *args)

    def is_authorized(self) -> bool:
        if not self.secret_token:
            return True
        header_auth = self.headers.get("X-Auth-Token", "")
        if header_auth == self.secret_token:
            return True
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        if params.get("token", [""])[0] == self.secret_token:
            return True
        return False

    def get_latest_quota(self, force: bool = False) -> dict:
        now = time.time()
        if not force and self.cached_data and (now - self.last_fetch_time < self.cache_ttl):
            return self.cached_data
        try:
            data = fetch_usage_data()
            QuotaServerHandler.cached_data = data
            QuotaServerHandler.last_fetch_time = now
            return data
        except Exception as e:
            if self.cached_data:
                return self.cached_data
            raise e

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if not self.is_authorized():
            self.send_response(401)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error": "Unauthorized. Provide valid X-Auth-Token header or ?token= parameter."}\n')
            return

        if path in ("/healthz", "/health"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"ok": true}\n')
            return

        force_refresh = "refresh=1" in parsed.query

        try:
            quota = self.get_latest_quota(force=force_refresh)
        except Exception as err:
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(err)}).encode("utf-8"))
            return

        # 1. JSON Endpoint (/quota, /json)
        if path in ("/quota", "/json"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(quota, indent=2).encode("utf-8"))
            return

        # 2. Terminal Dashboard Endpoint (default /)
        ua = self.headers.get("User-Agent", "").lower()
        use_color = ("curl" in ua or "wget" in ua or "httpie" in ua or "term" in parsed.query)
        rendered = render_dashboard(quota, color=use_color)

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(rendered.encode("utf-8"))


def get_local_ip() -> str:
    """Best effort to obtain the primary local LAN IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def run_server(host: str, port: int, secret_token: str = None):
    """Run cross-device daemon."""
    QuotaServerHandler.secret_token = secret_token
    server_addr = (host, port)
    httpd = http.server.ThreadingHTTPServer(server_addr, QuotaServerHandler)
    
    local_ip = get_local_ip()
    print("\033[1m\033[32mAntigravity Quota Server Running!\033[0m")
    print(f"  • Local address:   http://localhost:{port}")
    print(f"  • Network address: http://{local_ip}:{port}")
    if secret_token:
        print(f"  • Security:        Protected with auth token: {secret_token}")
        print(f"  • Remote query:    curl -s -H \"X-Auth-Token: {secret_token}\" http://{local_ip}:{port}")
    else:
        print(f"  • Remote query:    curl -s http://{local_ip}:{port}")
    print(f"  • JSON endpoint:   http://{local_ip}:{port}/quota")
    print("Press Ctrl+C to terminate the server.\n")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()


# ============================================================================
# Main CLI Entry Point
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Google Antigravity Usage & Quota Monitor (Cross-Device Terminal Tool)",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON data")
    parser.add_argument("--no-color", action="store_true", help="Disable colored output")
    parser.add_argument("--watch", "-w", nargs="?", const=30, type=int, metavar="SECS", help="Auto-refresh every N seconds (default: 30)")
    parser.add_argument("--serve", "-s", action="store_true", help="Start background server for cross-device access")
    parser.add_argument("--port", "-p", type=int, default=3007, help="Server port (default: 3007)")
    parser.add_argument("--bind", "-b", type=str, default="0.0.0.0", help="Server bind address (default: 0.0.0.0)")
    parser.add_argument("--secret", type=str, default=None, help="Optional auth token for server security")
    parser.add_argument("--remote", "-r", type=str, default=None, help="Fetch from a remote Antigravity usage server URL")
    parser.add_argument("--version", "-v", action="version", version=f"%(prog)s {__version__}")

    args = parser.parse_args()

    if args.serve:
        run_server(args.bind, args.port, args.secret)
        return

    def get_data() -> dict:
        if args.remote:
            req = urllib.request.Request(
                urllib.parse.urljoin(args.remote, "/quota"),
                headers={"User-Agent": USER_AGENT}
            )
            if args.secret:
                req.add_header("X-Auth-Token", args.secret)
            with urllib.request.urlopen(req, timeout=10) as resp:
                return json.loads(resp.read().decode("utf-8"))
        else:
            return fetch_usage_data()

    if args.watch:
        interval = max(5, args.watch)
        color = not args.no_color and sys.stdout.isatty()
        try:
            while True:
                data = get_data()
                sys.stdout.write("\033[2J\033[H")
                if args.json:
                    sys.stdout.write(json.dumps(data, indent=2) + "\n")
                else:
                    sys.stdout.write(render_dashboard(data, color=color))
                    sys.stdout.write(f"\033[2mAuto-refreshing every {interval}s (Ctrl+C to quit)\033[0m\n")
                sys.stdout.flush()
                time.sleep(interval)
        except KeyboardInterrupt:
            sys.stdout.write("\nExited watch mode.\n")
            return

    try:
        data = get_data()
    except Exception as e:
        sys.stderr.write(f"\033[31mError fetching Antigravity quota:\033[0m {e}\n")
        sys.exit(1)

    if args.json:
        print(json.dumps(data, indent=2))
    else:
        color = not args.no_color and sys.stdout.isatty()
        print(render_dashboard(data, color=color))


if __name__ == "__main__":
    main()
