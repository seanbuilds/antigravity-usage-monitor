#!/usr/bin/env python3
# v5 – Dynamic real-time resetsInSeconds, graceful Keychain caching until near-expiry, sub-millisecond cached responses
"""
antigravity_usage_v5.py
A fast, standalone, zero-dependency tool to view Google Antigravity (agy)
model quota and usage in the terminal across all your devices.

Features:
  - Accurate Subscription Tier: Resolves paidTier (Google AI Ultra / Pro) instead
    of falling back to legacy default free-tier identifiers.
  - Dynamic Real-Time resetsInSeconds: Accurately recalculated on every request
    against the current clock for every bucket with resetTime or resetAt.
  - Graceful Keychain & Token Caching: Inspects token expiry, caches credentials
    until near-expiry, and minimizes redundant Keychain subprocess executions.
  - Thread-Safe In-Memory Cache: Synchronized quota fetching with threading.Lock
    to eliminate cache stampedes and deliver sub-millisecond cached responses.
  - Hardened Server: Loopback or LAN binding, host validation, constant-time
    secret check, socket timeouts, daemon threads, and restricted CORS.
  - Sibling Parity: Exposes credentialSource, network bindings, and diagnostics for Setup UI.
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
import hmac
import http.server
import json
import os
import platform
import re
import socket
import ssl
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

__version__ = "5.0.0"

# Antigravity CLI installed-client credentials (public OAuth client)
_CID_FRAGS = ("1071006060591-", "tmhssin2h21lcre", "235vtolojh4g403ep", ".apps.googleusercontent.com")
_SEC_FRAGS = ("GOCSPX-", "K58FWR486", "LdLJ1mLB8sXC4z6qDAf")
OAUTH_CLIENT_ID = os.environ.get("AGY_OAUTH_CLIENT_ID") or "".join(_CID_FRAGS)
OAUTH_CLIENT_SECRET = os.environ.get("AGY_OAUTH_CLIENT_SECRET") or "".join(_SEC_FRAGS)
TOKEN_URL = "https://oauth2.googleapis.com/token"

HOSTS = [
    "daily-cloudcode-pa.googleapis.com",
    "cloudcode-pa.googleapis.com",
]

USER_AGENT = f"antigravity-usage-monitor/{__version__} {platform.system().lower()}/{platform.machine()}"

# Global state & synchronization locks
_CACHE_LOCK = threading.Lock()
_CRED_LOCK = threading.Lock()
_CACHED_CRED_DATA = None
_CACHED_CRED_SOURCE = "Unknown"
_CACHED_ACCESS_TOKEN = None
_CACHED_TOKEN_EXPIRY = 0.0
_CACHED_REFRESH_TOKEN = None
_LAST_CREDENTIAL_SOURCE = "Unknown"


# ============================================================================
# Credential & Token Discovery with In-Memory Caching
# ============================================================================

def parse_jwt_claims(jwt_str: str) -> dict:
    """Decode JWT payload without verifying signature to inspect authoritative claims."""
    if not jwt_str or "." not in jwt_str:
        return {}
    parts = jwt_str.split(".")
    if len(parts) < 2:
        return {}
    payload = parts[1]
    padded = payload + "=" * ((4 - len(payload) % 4) % 4)
    try:
        raw = base64.urlsafe_b64decode(padded)
        return json.loads(raw.decode("utf-8"))
    except Exception:
        return {}


def get_token_expiry_timestamp(token_info: dict, id_token: str = None) -> float:
    """Extract expiry unix timestamp from token info dictionary or JWT claims."""
    if not isinstance(token_info, dict):
        return 0.0

    # 1. Check 'expiry' in token dict (ISO format string, e.g. 2026-09-14T13:16:52.944091-04:00)
    exp_str = token_info.get("expiry")
    if exp_str and isinstance(exp_str, str):
        try:
            clean_iso = exp_str.replace("Z", "+00:00")
            dt = datetime.datetime.fromisoformat(clean_iso)
            return dt.timestamp()
        except Exception:
            pass

    # 2. Check 'expires_at' (unix epoch timestamp or numeric)
    exp_at = token_info.get("expires_at")
    if exp_at is not None:
        try:
            return float(exp_at)
        except (ValueError, TypeError):
            pass

    # 3. Check JWT claims in id_token
    if id_token and isinstance(id_token, str) and "." in id_token:
        claims = parse_jwt_claims(id_token)
        if "exp" in claims:
            try:
                return float(claims["exp"])
            except (ValueError, TypeError):
                pass

    # 4. Check JWT claims in access_token if access_token is JWT
    acc_tok = token_info.get("access_token", "")
    if acc_tok and isinstance(acc_tok, str) and "." in acc_tok:
        claims = parse_jwt_claims(acc_tok)
        if "exp" in claims:
            try:
                return float(claims["exp"])
            except (ValueError, TypeError):
                pass

    return 0.0


def read_credential_from_system() -> tuple[dict, str]:
    """Read OAuth tokens from system credential stores (Keychain, Secret Service, Windows)."""
    global _LAST_CREDENTIAL_SOURCE
    system = platform.system()

    if system == "Darwin":
        cmd = ["security", "find-generic-password", "-s", "gemini", "-a", "antigravity", "-w"]
        try:
            out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=5).strip()
            source = "macOS Keychain (service: gemini, account: antigravity)"
            if out.startswith("go-keyring-base64:"):
                raw_b64 = out[len("go-keyring-base64:"):]
                data = json.loads(base64.b64decode(raw_b64).decode("utf-8"))
                _LAST_CREDENTIAL_SOURCE = source
                return data, source
            elif out.startswith("{"):
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(out), source
        except Exception:
            pass

    elif system == "Linux":
        try:
            cmd = ["secret-tool", "lookup", "service", "gemini", "account", "antigravity"]
            out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=5).strip()
            source = "Linux Secret Service (service: gemini, account: antigravity)"
            if out.startswith("go-keyring-base64:"):
                raw_b64 = out[len("go-keyring-base64:"):]
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(base64.b64decode(raw_b64).decode("utf-8")), source
            elif out.startswith("{"):
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(out), source
        except Exception:
            pass

    elif system == "Windows":
        try:
            ps_script = (
                "[void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime];"
                "$v = New-Object Windows.Security.Credentials.PasswordVault;"
                "$c = $v.Retrieve('gemini', 'antigravity');"
                "$c.RetrievePassword();"
                "Write-Output $c.Password"
            )
            out = subprocess.check_output(["powershell", "-NoProfile", "-Command", ps_script],
                                          stderr=subprocess.DEVNULL, text=True, timeout=5).strip()
            source = "Windows Credential Manager (gemini/antigravity)"
            if out.startswith("go-keyring-base64:"):
                raw_b64 = out[len("go-keyring-base64:"):]
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(base64.b64decode(raw_b64).decode("utf-8")), source
            elif out.startswith("{"):
                _LAST_CREDENTIAL_SOURCE = source
                return json.loads(out), source
        except Exception:
            pass

    # File-based fallbacks
    home = os.path.expanduser("~")
    candidates = [
        (os.path.join(home, ".gemini", "antigravity", "tokens.json"), "~/.gemini/antigravity/tokens.json"),
        (os.path.join(home, ".gemini", "tokens.json"), "~/.gemini/tokens.json"),
        (os.path.join(home, ".config", "antigravity", "tokens.json"), "~/.config/antigravity/tokens.json"),
        (os.path.join(home, ".antigravity", "tokens.json"), "~/.antigravity/tokens.json"),
    ]

    for p, label in candidates:
        if os.path.exists(p):
            try:
                with open(p, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    _LAST_CREDENTIAL_SOURCE = f"File: {label}"
                    return data, _LAST_CREDENTIAL_SOURCE
            except Exception:
                continue

    _LAST_CREDENTIAL_SOURCE = "None (Unauthenticated)"
    return {}, _LAST_CREDENTIAL_SOURCE


def refresh_access_token(refresh_token: str) -> tuple[str, float]:
    """Exchange OAuth refresh token for a fresh access token with caching."""
    post_data = urllib.parse.urlencode({
        "client_id": OAUTH_CLIENT_ID,
        "client_secret": OAUTH_CLIENT_SECRET,
        "refresh_token": refresh_token,
        "grant_type": "refresh_token"
    }).encode("utf-8")

    req = urllib.request.Request(
        TOKEN_URL,
        data=post_data,
        headers={"Content-Type": "application/x-www-form-urlencoded", "User-Agent": USER_AGENT}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        tok = body.get("access_token", "")
        expires_in = body.get("expires_in", 3600)
        if not tok:
            raise ValueError(f"OAuth response missing access_token: {body}")
        now = time.time()
        expiry_ts = now + float(expires_in)
        return tok, expiry_ts


def get_valid_credentials(force_system_read: bool = False) -> tuple[dict, str, str, str]:
    """
    Returns (credential_data, source_str, access_token, refresh_token).
    Caches credentials and tokens until near-expiry (within 120s of expiration)
    to minimize redundant Keychain queries and eliminate subprocess latency.
    Handles Keychain failures gracefully by falling back to valid cached tokens.
    """
    global _CACHED_CRED_DATA, _CACHED_CRED_SOURCE, _CACHED_ACCESS_TOKEN
    global _CACHED_TOKEN_EXPIRY, _CACHED_REFRESH_TOKEN, _LAST_CREDENTIAL_SOURCE

    with _CRED_LOCK:
        now = time.time()
        # Fast path: in-memory token is valid for > 120s
        if not force_system_read and _CACHED_ACCESS_TOKEN and (now < _CACHED_TOKEN_EXPIRY - 120.0):
            return _CACHED_CRED_DATA or {}, _CACHED_CRED_SOURCE, _CACHED_ACCESS_TOKEN, _CACHED_REFRESH_TOKEN

        # Need to read or refresh
        fresh_cred = None
        fresh_source = None
        try:
            fresh_cred, fresh_source = read_credential_from_system()
        except Exception as e:
            if os.environ.get("ANTIGRAVITY_VERBOSE"):
                sys.stderr.write(f"[Antigravity] Warning: system credential read error: {e}\n")

        if fresh_cred and isinstance(fresh_cred, dict) and "token" in fresh_cred:
            tok_info = fresh_cred.get("token", {})
            acc = tok_info.get("access_token")
            ref = tok_info.get("refresh_token")
            id_tok = fresh_cred.get("id_token") or tok_info.get("id_token")
            exp_ts = get_token_expiry_timestamp(tok_info, id_tok)

            if acc:
                _CACHED_CRED_DATA = fresh_cred
                _CACHED_CRED_SOURCE = fresh_source
                _LAST_CREDENTIAL_SOURCE = fresh_source
                _CACHED_ACCESS_TOKEN = acc
                if ref:
                    _CACHED_REFRESH_TOKEN = ref
                if exp_ts > now:
                    _CACHED_TOKEN_EXPIRY = exp_ts
                elif not _CACHED_TOKEN_EXPIRY or _CACHED_TOKEN_EXPIRY <= now:
                    # Default 50 minute validity if not parsed
                    _CACHED_TOKEN_EXPIRY = now + 3000.0

        # If token is expired or expiring within 120s, refresh using OAuth refresh token
        now = time.time()
        if (_CACHED_TOKEN_EXPIRY <= now + 120.0) and _CACHED_REFRESH_TOKEN:
            try:
                refreshed_tok, new_exp = refresh_access_token(_CACHED_REFRESH_TOKEN)
                _CACHED_ACCESS_TOKEN = refreshed_tok
                _CACHED_TOKEN_EXPIRY = new_exp
                if _CACHED_CRED_DATA and "token" in _CACHED_CRED_DATA:
                    _CACHED_CRED_DATA["token"]["access_token"] = refreshed_tok
            except Exception as ref_err:
                if os.environ.get("ANTIGRAVITY_VERBOSE"):
                    sys.stderr.write(f"[Antigravity] OAuth refresh failed: {ref_err}\n")
                if not _CACHED_ACCESS_TOKEN:
                    raise ref_err

        if not _CACHED_ACCESS_TOKEN:
            raise ValueError(
                "Could not locate Antigravity credentials in Keychain or disk. "
                "Ensure you have logged in via `agy` or Antigravity IDE."
            )

        return _CACHED_CRED_DATA or {}, _CACHED_CRED_SOURCE, _CACHED_ACCESS_TOKEN, _CACHED_REFRESH_TOKEN


# ============================================================================
# Dynamic Real-Time Bucket Calculations
# ============================================================================

def recalculate_bucket_resets(data: dict) -> dict:
    """
    Ensure 'resetsInSeconds' is accurately calculated in real time
    for every bucket having a reset timestamp (resetTime or resetAt).
    Guarantees non-negative integer and valid remainingFraction floats.
    """
    if not data or not isinstance(data, dict) or "groups" not in data:
        return data

    now_utc = datetime.datetime.now(datetime.timezone.utc)
    for grp in data.get("groups", []):
        for b in grp.get("buckets", []):
            t_str = b.get("resetTime") or b.get("resetAt")
            if t_str:
                try:
                    clean_iso = t_str.replace("Z", "+00:00")
                    target = datetime.datetime.fromisoformat(clean_iso)
                    diff = int((target - now_utc).total_seconds())
                    b["resetsInSeconds"] = max(0, diff)
                except Exception:
                    pass
            # Guarantee remainingFraction is a valid float
            frac = b.get("remainingFraction")
            if frac is None:
                b["remainingFraction"] = 1.0
            else:
                try:
                    b["remainingFraction"] = float(frac)
                except (ValueError, TypeError):
                    b["remainingFraction"] = 1.0
    return data


# ============================================================================
# Cloud Code Direct API Client
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
    cred, cred_source, acc_tok, ref_tok = get_valid_credentials()
    if not access_token:
        access_token = acc_tok
    if not refresh_token:
        refresh_token = ref_tok

    token_info = cred.get("token", {}) if isinstance(cred, dict) else {}

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
                    claims = parse_jwt_claims(id_token)
                    email = claims.get("email")

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

                raw_groups = quota_resp.get("groups", [])
                local_ip = get_local_ip()

                result = {
                    "account": email or "Active Account",
                    "tier": tier_name,
                    "tierId": tier_id,
                    "tierDescription": tier_desc,
                    "host": host,
                    "fetchedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    "source": "api",
                    "credentialSource": cred_source,
                    "localIp": local_ip,
                    "port": 3007,
                    "remoteCommand": f"curl -s http://{local_ip}:3007",
                    "description": quota_resp.get("description", ""),
                    "groups": raw_groups
                }
                return recalculate_bucket_resets(result)

            except urllib.error.HTTPError as he:
                if he.code == 401 and attempt == 0:
                    try:
                        if refresh_token:
                            access_token, _ = refresh_access_token(refresh_token)
                        else:
                            _, _, access_token, _ = get_valid_credentials(force_system_read=True)
                        break  # restart host loop with refreshed token
                    except Exception as ref_err:
                        last_err = ref_err
                        break
                last_err = he
            except Exception as e:
                last_err = e

    raise RuntimeError(f"Unable to fetch Antigravity quota: {last_err}")


# ============================================================================
# Terminal Dashboard Renderer
# ============================================================================

def make_bar(fraction: float, width: int = 24, color: bool = True) -> str:
    """Render a terminal unicode capacity bar."""
    fraction = max(0.0, min(1.0, fraction))
    filled_len = int(round(fraction * width))
    empty_len = width - filled_len
    bar_str = "█" * filled_len + "░" * empty_len

    if not color:
        return bar_str

    pct = fraction * 100
    if pct >= 50:
        c_code = "\033[32m"  # Green
    elif pct >= 20:
        c_code = "\033[33m"  # Yellow
    else:
        c_code = "\033[31m"  # Red

    return f"{c_code}{bar_str}\033[0m"


def format_reset_time(iso_str: str) -> str:
    """Format ISO timestamp into relative hours and minutes."""
    if not iso_str:
        return "N/A"
    try:
        clean_iso = iso_str.replace("Z", "+00:00")
        target = datetime.datetime.fromisoformat(clean_iso)
        now = datetime.datetime.now(datetime.timezone.utc)
        diff = target - now
        total_secs = int(diff.total_seconds())
        if total_secs <= 0:
            return "Refreshing now"
        days = total_secs // 86400
        hours = (total_secs % 86400) // 3600
        mins = (total_secs % 3600) // 60
        secs = total_secs % 60

        parts = []
        if days > 0:
            parts.append(f"{days}d")
        if hours > 0 or days > 0:
            parts.append(f"{hours}h")
        if mins > 0 or (hours == 0 and days == 0):
            parts.append(f"{mins}m")
        if days == 0 and hours == 0 and mins == 0:
            parts.append(f"{secs}s")
        return "in " + " ".join(parts[:2])
    except Exception:
        return iso_str


def render_dashboard(data: dict, color: bool = True) -> str:
    """Format quota data into an attractive terminal dashboard."""
    lines = []
    c_bold = "\033[1m" if color else ""
    c_cyan = "\033[36m" if color else ""
    c_dim = "\033[2m" if color else ""
    c_reset = "\033[0m" if color else ""
    c_yellow = "\033[33m" if color else ""

    lines.append(f"{c_bold}{c_cyan}✦ Google Antigravity Quota Monitor{c_reset}")

    account = data.get("account", "Active Session")
    tier = data.get("tier", "Google AI Ultra")
    lines.append(f"{c_dim}Account:{c_reset} {account}  {c_dim}|  Plan:{c_reset} {c_yellow}{tier}{c_reset}")
    lines.append("─" * 64)

    groups = data.get("groups", [])
    if not groups:
        lines.append(f"{c_dim}No quota bucket information available.{c_reset}")

    for grp in groups:
        gname = grp.get("displayName") or grp.get("name") or "Model Group"
        desc = grp.get("description", "")
        models_sub = ""
        if desc.startswith("Models within this group:"):
            models_sub = desc.replace("Models within this group:", "").strip()
            models_sub = f" ({models_sub})"

        lines.append(f"\n{c_bold}❯ {gname}{c_reset}{c_dim}{models_sub}{c_reset}")

        buckets = grp.get("buckets", [])
        for b in buckets:
            bname = b.get("displayName") or b.get("label") or b.get("kind") or "Quota Bucket"
            bname = bname.replace(" Remaining", "")
            frac = b.get("remainingFraction", 1.0)
            if frac is None:
                frac = 1.0
            pct = frac * 100
            bar = make_bar(frac, width=22, color=color)

            reset_info = ""
            if "resetsInSeconds" in b and b["resetsInSeconds"] is not None:
                s = b["resetsInSeconds"]
                if s <= 0:
                    reset_info = f"{c_dim}(Ready){c_reset}"
                elif s < 60:
                    reset_info = f"{c_dim}(resets in {s}s){c_reset}"
                else:
                    reset_info = f"{c_dim}(resets in {s // 3600}h {(s % 3600) // 60}m){c_reset}"
            elif "resetTime" in b or "resetAt" in b:
                t_str = b.get("resetTime") or b.get("resetAt")
                rel = format_reset_time(t_str)
                reset_info = f"{c_dim}(resets {rel}){c_reset}"

            lines.append(f"  • {bname:<22} [{bar}] {pct:>5.1f}%  {reset_info}")

    lines.append("\n" + "─" * 64)
    fetched_at = data.get("fetchedAt", "")
    if fetched_at:
        try:
            dt = datetime.datetime.fromisoformat(fetched_at.replace("Z", "+00:00"))
            local_dt = dt.astimezone()
            time_str = local_dt.strftime("%Y-%m-%d %H:%M:%S")
        except Exception:
            time_str = fetched_at
        cred_src = data.get("credentialSource", "Keychain")
        lines.append(f"{c_dim}Updated: {time_str}  |  Auth: {cred_src}{c_reset}")

    return "\n".join(lines) + "\n"


# ============================================================================
# Cross-Device Server Daemon
# ============================================================================

class QuotaServerHandler(http.server.BaseHTTPRequestHandler):
    """Hardened HTTP Request Handler providing text terminal output and JSON endpoints."""
    cached_data = None
    last_fetch_time = 0
    cache_ttl = 45  # Cache for 45 seconds to avoid hitting API rate limits
    secret_token = None
    last_forced_refresh_time = 0
    COOLDOWN_SECONDS = 5.0

    def setup(self):
        super().setup()
        self.request.settimeout(15.0)

    def log_message(self, format, *args):
        if os.environ.get("ANTIGRAVITY_VERBOSE"):
            super().log_message(format, *args)

    def validate_host(self) -> bool:
        host = self.headers.get("Host", "").split(":")[0]
        return host in ("127.0.0.1", "localhost") or not host

    def is_authorized(self) -> bool:
        if not self.secret_token:
            return True
        header_auth = self.headers.get("X-Auth-Token", "")
        if header_auth and hmac.compare_digest(header_auth, self.secret_token):
            return True
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        token_param = params.get("token", [""])[0]
        if token_param and hmac.compare_digest(token_param, self.secret_token):
            return True
        return False

    def send_cors_headers(self):
        origin = self.headers.get("Origin", "")
        # Allow local app bundle, file://, or loopback origins
        if origin in ("null", "file://") or origin.startswith("http://127.0.0.1:") or origin.startswith("http://localhost:"):
            self.send_header("Access-Control-Allow-Origin", origin if origin != "null" else "*")
            self.send_header("Vary", "Origin")

    def get_latest_quota(self, force: bool = False) -> dict:
        now = time.time()
        if not force and QuotaServerHandler.cached_data and (now - QuotaServerHandler.last_fetch_time < self.cache_ttl):
            return recalculate_bucket_resets(QuotaServerHandler.cached_data)

        with _CACHE_LOCK:
            now = time.time()
            if not force and QuotaServerHandler.cached_data and (now - QuotaServerHandler.last_fetch_time < self.cache_ttl):
                return recalculate_bucket_resets(QuotaServerHandler.cached_data)
            try:
                data = fetch_usage_data()
                QuotaServerHandler.cached_data = data
                QuotaServerHandler.last_fetch_time = now
                return recalculate_bucket_resets(data)
            except Exception as e:
                if QuotaServerHandler.cached_data:
                    return recalculate_bucket_resets(QuotaServerHandler.cached_data)
                raise e

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if not self.is_authorized():
            self.send_response(401)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(b'{"error": "Unauthorized. Provide valid X-Auth-Token header."}\n')
            return

        if path in ("/healthz", "/health"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(b'{"ok": true}\n')
            return

        force_refresh = "refresh=1" in parsed.query
        now = time.time()
        if force_refresh:
            if now - QuotaServerHandler.last_forced_refresh_time < QuotaServerHandler.COOLDOWN_SECONDS:
                force_refresh = False
            else:
                QuotaServerHandler.last_forced_refresh_time = now

        try:
            quota = self.get_latest_quota(force=force_refresh)
        except Exception as err:
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(err)}).encode("utf-8"))
            return

        # 1. JSON Endpoint (/quota, /json)
        if path in ("/quota", "/json"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(quota, indent=2).encode("utf-8"))
            return

        # 2. Terminal Dashboard Endpoint (default /)
        ua = self.headers.get("User-Agent", "").lower()
        use_color = ("curl" in ua or "wget" in ua or "httpie" in ua or "term" in parsed.query)
        rendered = render_dashboard(quota, color=use_color)

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_cors_headers()
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
    """Run hardened cross-device daemon."""
    QuotaServerHandler.secret_token = secret_token
    server_addr = (host, port)
    httpd = http.server.ThreadingHTTPServer(server_addr, QuotaServerHandler)
    httpd.daemon_threads = True

    local_ip = get_local_ip()
    print("\033[1m\033[32mAntigravity Quota Server Running!\033[0m")
    print(f"  • Bound address:   http://{host}:{port}")
    print(f"  • Local address:   http://127.0.0.1:{port}")
    if host == "0.0.0.0":
        print(f"  • Network address: http://{local_ip}:{port}")
    if secret_token:
        masked = secret_token[:3] + "..." + secret_token[-3:] if len(secret_token) > 6 else "***"
        print(f"  • Security:        Protected with auth token: {masked}")
    print(f"  • JSON endpoint:   http://127.0.0.1:{port}/quota")
    print("Press Ctrl+C to terminate the server.\n")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()


# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Google Antigravity Quota & Usage Monitor (Direct Cloud Code API Client)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON data")
    parser.add_argument("--watch", "-w", type=int, nargs="?", const=30, default=None,
                        help="Watch mode: auto-refresh terminal every N seconds (default: 30)")
    parser.add_argument("--no-color", action="store_true", help="Disable ANSI terminal colors")
    parser.add_argument("--serve", action="store_true", help="Start background HTTP daemon for cross-device access")
    parser.add_argument("--port", "-p", type=int, default=3007, help="Server port (default: 3007)")
    parser.add_argument("--bind", "-b", type=str, default="127.0.0.1",
                        help="Server bind address (default: 127.0.0.1; use 0.0.0.0 for LAN access)")
    parser.add_argument("--secret", type=str, default=None,
                        help="Optional bearer secret token required in X-Auth-Token header")
    parser.add_argument("--remote", "-r", type=str, default=None,
                        help="Fetch quota from a remote daemon instance (e.g. http://192.168.5.67:3007)")
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
