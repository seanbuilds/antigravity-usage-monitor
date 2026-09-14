<!-- v1 – Enterprise Security Lead Review -->
# Enterprise Security, Privacy & Architecture Review
## Antigravity & Grok Usage Monitor Suite

**Reviewer:** Enterprise Security & Privacy Lead (Consumer Persona 4)  
**Target Repository:** `/Users/dad/git/antigravity-usage-monitor/`  
**Target Artifacts:** `SharedQuotaKit`, `AntigravityUsageApp`, `GrokUsageApp`, `AntigravityWidget`, `GrokWidget`, legacy Python daemons (`antigravity_usage_v5.py`, `grok_usage_v7.py`), and entitlement configurations.  
**Evaluation Date:** September 14, 2026  
**Operational Scope:** Workstation hygiene, credential storage, attack surface reduction, process isolation, App Group sandboxing, battery efficiency, and corporate deployment governance.

---

## Executive Summary & Governance Rating

| Assessment Domain | Rating | Status | Primary Finding |
| :--- | :---: | :---: | :--- |
| **Credential Security & Storage** | **3.5 / 5.0** | Amber | macOS Keychain integration via `SecItemCopyMatching` is safe, but Swift fallback lacks Go-keyring base64 unpacking and token refresh logic. `~/.grok/auth.json` on-disk fallback introduces plaintext risk. |
| **Attack Surface & Process Isolation** | **2.5 / 5.0** | Red | Active Python daemon binds to `0.0.0.0:3007` without mandatory authentication, broadcasting user identity and usage telemetry over the local network. Direct Swift HTTPS transition remains incomplete. |
| **Sandboxing & App Group Security** | **3.0 / 5.0** | Amber | App Sandbox is disabled. App Group `group.com.dad.aiusage` stores no secrets in shared `UserDefaults`, but persists plaintext user email addresses (PII) accessible to any local user process. |
| **Resource & Battery Hygiene** | **3.5 / 5.0** | Amber | Native SwiftUI memory is compact (~64–70 MB RSS), but an unthrottled 1.0-second timer forces continuous 0.8%–1.0% CPU load and wakes CPU cores from deep power-saving states. |
| **Overall Enterprise Readiness** | **B- (2.9 / 5.0)** | **Pilot Grade** | Suitable for controlled individual developer use; **Blocked** for fleet-wide corporate deployment pending Developer ID signing, Notarization, localhost-only binding, and timer throttling. |

### Governance Verdict
The transition of the Antigravity and Grok Usage Monitor suite from a legacy hybrid WebKit/subprocess architecture to a **100% pure native Swift, SwiftUI, AppKit, and WidgetKit** application suite represents a significant architectural improvement in workstation memory consumption, UI responsiveness, and code auditability. Memory usage has plummeted by over 70% (from ~280 MB down to ~64–70 MB RSS).

However, from an enterprise cybersecurity and workstation hygiene perspective, the codebase currently sits in a **transitional architecture state**. While the user interface layer is fully native Swift, the operational runtime on the local machine remains tethered to background Python HTTP daemons (`antigravity_usage_v5.py` and `grok_usage_v7.py`). Most critically, the running Antigravity daemon binds to `0.0.0.0:3007` without authentication, leaking developer identity and rate-limit activity across the local subnet. Furthermore, native Swift fallback paths to upstream Google Cloud Code APIs currently fail because they do not decode the base64-serialized Go-keyring JSON payload stored in the macOS Keychain.

Remediating these findings requires severing the dependency on local HTTP daemon ports, completing pure native OAuth token lifecycle handling in Swift, enabling macOS App Sandboxing with network client entitlements, and implementing energy-coalesced UI timers.

---

## 1. Credential Security, Key Management & Storage

### 1.1 macOS Keychain Integration (`KeychainHelper.swift`)
The core credential retrieval utility is implemented in [`Sources/SharedQuotaKit/Security/KeychainHelper.swift`](file:///Users/dad/git/antigravity-usage-monitor/Sources/SharedQuotaKit/Security/KeychainHelper.swift):

```swift
public enum KeychainHelper {
    public static func readPassword(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
```

#### Security Findings & Invariants:
1. **Appropriate Native API Usage**: The implementation uses Apple's native `Security.framework` (`SecItemCopyMatching` with `kSecClassGenericPassword`), avoiding vulnerable shell execution patterns such as `Process()` or `/usr/bin/security`. This prevents command injection vulnerabilities and avoids spawning unmonitored child processes.
2. **Missing Keychain Accessibility Constraints**: When saving credentials (`savePassword`), the dictionary omits `kSecAttrAccessible`. By default, macOS applies standard accessibility. For enterprise-grade credential storage, items must be restricted with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` or `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` to prevent unauthorized extraction during locked states or unintended synchronization across iCloud Keychain.
3. **No Keychain Access Group Isolation**: Because the application is not compiled with App Sandbox and lacks `keychain-access-groups` entitlements, any generic password query accesses the default user login keychain without cryptographic application partitioning.

### 1.2 The Go-Keyring Base64 Extraction Defect in Native Swift
A critical ground-truth gap exists between how the Antigravity CLI stores credentials in the Keychain and how [`Sources/AntigravityUsageApp/AntigravityDataProvider.swift`](file:///Users/dad/git/antigravity-usage-monitor/Sources/AntigravityUsageApp/AntigravityDataProvider.swift) attempts to consume them:

```swift
// AntigravityDataProvider.swift (lines 33-46)
guard let token = KeychainHelper.readPassword(service: "gemini", account: "antigravity") else {
    throw NSError(domain: "AntigravityDataProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "No Antigravity credential found in Keychain"])
}
...
var req = URLRequest(url: url)
req.httpMethod = "POST"
req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

#### Root Evidence Verification:
Inspecting the authoritative raw Keychain entry stored by the Antigravity CLI on macOS reveals that the stored secret is **not** a raw OAuth bearer token string. Instead, it is formatted as:
```text
go-keyring-base64:eyJ0b2t...
```
This payload is a base64-encoded JSON blob containing OAuth access tokens, refresh tokens, and expiry timestamps generated by the Antigravity Go tool suite.

* **Impact**: When `AntigravityDataProvider.swift` attempts its native Priority 2 fallback (`fetchFromCloudCodeAPI`), it transmits `Authorization: Bearer go-keyring-base64:eyJ0b2t...` directly to `https://daily-cloudcode-pa.googleapis.com`. The upstream Google API promptly rejects the request with HTTP `401 Unauthorized`.
* **Architectural Consequence**: Because the pure native Swift fallback is broken, the app is strictly dependent on Priority 1 (`http://127.0.0.1:3007/quota`), which delegates token parsing to the legacy Python daemon `antigravity_usage_v5.py`. The promised "pure native" operational independence is currently incomplete.

### 1.3 Disk-Based Fallback Risks (`~/.grok/auth.json` and Legacy Fallbacks)
1. **Grok Credential Extraction**: In [`Sources/GrokUsageApp/GrokDataProvider.swift`](file:///Users/dad/git/antigravity-usage-monitor/Sources/GrokUsageApp/GrokDataProvider.swift) (lines 116–130), Priority 2 inspects `~/.grok/auth.json`:
   ```swift
   let authPath = NSString(string: "~/.grok/auth.json").expandingTildeInPath
   guard let data = try? Data(contentsOf: URL(fileURLWithPath: authPath)), ...
   ```
   Root verification on the audit machine confirms `/Users/dad/.grok/auth.json` exists with file mode `0600` (`-rw-------`). While the file permissions restrict access to the current user, storing unencrypted refresh tokens and OAuth sessions in plaintext on the local filesystem represents a lateral movement risk for compromised developer workstations. All tokens must be migrated to the macOS Keychain.
2. **Synthetic Data Exposure**: Inspection of `GrokDataProvider.swift` (lines 131–168) reveals that when reading `~/.grok/auth.json`, the provider extracts the user's name and email, but returns **hardcoded mock numbers** (`fraction: 0.85`, `resetsInSeconds: 536000`, `fraction: 0.976`). This violates the ground-truth invariant by displaying synthetic numbers without communicating that live network retrieval failed.
3. **Legacy Python Candidate Paths**: Legacy script `antigravity_usage_v5.py` listed candidate paths (`~/.gemini/antigravity/tokens.json`, `~/.config/antigravity/tokens.json`). Verification confirmed that none of these plaintext files exist on disk, confining active Google credentials to the macOS Keychain.

---

## 2. Attack Surface & Process Isolation

### 2.1 Network Binding: `0.0.0.0:3007` vs. `127.0.0.1:3007` vs. Pure Native HTTPS
During live process auditing, the following background processes were active:

```text
PID   USER  %CPU  RSS   COMMAND
39366 dad   0.0   12MB  python antigravity_usage_v5.py --serve --port 3007 --bind 0.0.0.0
36833 dad   0.1   19MB  python grok_usage_v7.py --serve --port 3008 --bind 127.0.0.1
44618 dad   1.0   70MB  /Applications/Antigravity Usage.app/Contents/MacOS/Antigravity Usage
47499 dad   0.8   64MB  /Applications/Grok Usage.app/Contents/MacOS/Grok Usage
```

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               ATTACK SURFACE COMPARISON                                │
├────────────────────────────┬─────────────────────────────┬─────────────────────────────┤
│ Architectural Dimension    │ Legacy Daemon (0.0.0.0)     │ Pure Native Swift (Direct)  │
├────────────────────────────┼─────────────────────────────┼─────────────────────────────┤
│ Listening TCP Sockets      │ Open (0.0.0.0:3007)         │ NONE (Zero listening ports) │
│ Network Accessibility      │ Entire Subnet / LAN / Wi-Fi │ Confined to process memory  │
│ Exposure to Port Scanners  │ High (Nmap, Shodan, Masscan)│ Zero attack surface         │
│ Transport Security         │ Plaintext HTTP              │ Enforced TLS 1.3 HTTPS      │
│ Authentication Default     │ None (Unless --secret set)  │ System OAuth Token / Bearer │
│ DNS Rebinding Risk         │ Present                     │ Eliminated                  │
│ Cross-Origin Leaks (CORS)  │ Present (null origin leak)  │ Eliminated                  │
└────────────────────────────┴─────────────────────────────┴─────────────────────────────┘
```

#### Critical Vulnerability: Unauthenticated Subnet Telemetry Leak
`antigravity_usage_v5.py` was launched with `--bind 0.0.0.0`. In `QuotaServerHandler.is_authorized()`:
```python
def is_authorized(self) -> bool:
    if not self.secret_token:
        return True
    ...
```
Because no `--secret` token was configured in the execution arguments, **any endpoint on the corporate local network, shared Wi-Fi, or corporate VPN can issue a simple HTTP request (`curl http://<workstation-ip>:3007/quota`)** to extract:
* The developer's primary corporate Google account email (`ohheysean@gmail.com`).
* The active subscription tier (`Google AI Ultra`).
* Exact remaining quotas across Gemini and Claude/GPT model families.
* Real-time coding and model usage velocity patterns.

#### CORS Misconfiguration in Python Daemon
In `antigravity_usage_v5.py` (lines 648–653):
```python
def send_cors_headers(self):
    origin = self.headers.get("Origin", "")
    if origin in ("null", "file://") or origin.startswith("http://127.0.0.1:") or origin.startswith("http://localhost:"):
        self.send_header("Access-Control-Allow-Origin", origin if origin != "null" else "*")
```
When `origin == "null"`, the daemon emits `Access-Control-Allow-Origin: *`. Sandboxed iframes and local HTML files frequently execute with an opaque `null` origin. A malicious webpage visited in a standard browser could trigger a cross-origin fetch to `http://127.0.0.1:3007/quota` and exfiltrate the developer's internal usage data.

#### Security Benefits of Direct Native HTTPS
Eliminating both daemon scripts and routing requests through pure native Swift `URLSession` provides profound security advantages:
1. **Zero Open Ports**: The host does not listen on any network port. No firewall rules or local loopback access policies are required.
2. **Elimination of Inter-Process HTTP**: Inter-process communication over unauthenticated TCP loopback (`127.0.0.1`) is susceptible to port collision, process hijacking, and unauthorized local sniffing. Direct HTTPS terminates TLS directly within the application memory space.
3. **Subprocess Elimination**: Legacy iterations invoked `/bin/bash` to run `curl` commands. Pure native Swift uses compiled system frameworks, eliminating process creation overhead and command injection vectors.

---

## 3. Sandboxing & App Group Security

### 3.1 Entitlements & Code Signing Analysis
Inspection of [`antigravity.entitlements`](file:///Users/dad/git/antigravity-usage-monitor/antigravity.entitlements) and the compiled binary via `codesign -d --entitlements :- "/Applications/Antigravity Usage.app"` reveals:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.dad.aiusage</string>
    </array>
</dict>
</plist>
```

#### Security Deficiencies:
1. **App Sandbox is Disabled**: The entitlement `com.apple.security.app-sandbox` is completely absent. The application runs with unconfined user privileges, allowing unrestricted filesystem access (outside Apple's privacy-gated TCC directories).
2. **Ad-Hoc Code Signing**: Binaries are packaged with `codesign --sign -`. In macOS enterprise environments managed by MDM (Jamf Pro, Kandji, Microsoft Intune), ad-hoc signed applications trigger Gatekeeper blocks, fail system integrity policies, and cannot be distributed via self-service software catalogs.
3. **Unvalidated App Groups**: In standard Apple sandboxing, Application Groups require provisioning profiles linked to an authoritative Apple Developer Team ID (`<TeamID>.group.com.dad.aiusage`). With ad-hoc signatures on macOS, the kernel does not enforce team-scoped container boundaries.

### 3.2 App Group Persistence (`AppGroupPersistence.swift`)
The IPC bridge between the menu bar application and WidgetKit extensions is managed by [`Sources/SharedQuotaKit/Persistence/AppGroupPersistence.swift`](file:///Users/dad/git/antigravity-usage-monitor/Sources/SharedQuotaKit/Persistence/AppGroupPersistence.swift).

#### On-Disk Plist Inspection:
Auditing `/Users/dad/Library/Group Containers/group.com.dad.aiusage/Library/Preferences/group.com.dad.aiusage.plist` shows the exact stored dictionary:
```text
{
  "antigravity.account" => "ohheysean@gmail.com"
  "antigravity.lastUpdated" => 2026-09-14 19:36:00 +0000
  "antigravity.quotaPercent" => 81
  "antigravity.resetsIn" => 7424
  "antigravity.snapshot" => <1357 bytes JSON blob>
  "antigravity.tier" => "Google AI Ultra"
  "grok.account" => "Sun Glasses (sean.tyler@me.com)"
  "grok.lastUpdated" => 2026-09-14 19:36:06 +0000
  "grok.quotaPercent" => 84
  "grok.resetsIn" => 525417
  "grok.snapshot" => <667 bytes JSON blob>
  "grok.tier" => "SuperGrok Heavy"
}
```

#### Findings:
1. **No Token Leakage (Verified Ground Truth)**: Inspecting both the encoded `UnifiedQuotaSnapshot` JSON and individual keys confirms that **no bearer tokens, OAuth refresh tokens, or API secrets are stored in shared `UserDefaults`**. The persistence layer only stores public quota percentages, reset countdowns, tier names, and account labels.
2. **PII Classification**: User email addresses (`ohheysean@gmail.com` and `sean.tyler@me.com`) are persisted in plaintext. In privacy-conscious enterprises, displaying user handles or masked identifiers (e.g., `o***n@gmail.com`) is recommended to prevent casual shoulder-surfing or automated file scrapers from harvesting corporate user identities.
3. **Tamper Resilience**: Because the container directory `/Users/dad/Library/Group Containers/group.com.dad.aiusage` has standard user permissions (`drwx------`), any script or utility running under the user's account can modify this file. While spoofing quota percentages does not grant access to upstream accounts, the application should validate decoded schema integrity before rendering.

---

## 4. Resource Utilization, Battery Impact & Workstation Hygiene

### 4.1 Real-Time Resource Profile
Live metrics measured across running components on macOS:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              SYSTEM RESOURCE BENCHMARK                                 │
├──────────────────────────────┬─────────────┬─────────────┬─────────────┬───────────────┤
│ Process / Component          │ PID         │ % CPU       │ Memory (RSS)│ Thread Count  │
├──────────────────────────────┼─────────────┼─────────────┼─────────────┼───────────────┤
│ Antigravity Usage.app        │ 44618       │ 0.8% - 1.0% │ 70.1 MB     │ 6             │
│ Grok Usage.app               │ 47499       │ 0.8% - 1.0% │ 64.3 MB     │ 5             │
│ antigravity_usage_v5.py      │ 39366       │ 0.0%        │ 12.4 MB     │ 2             │
│ grok_usage_v7.py             │ 36833       │ 0.1%        │ 19.1 MB     │ 2             │
│ Total Combined Footprint     │ —           │ ~1.8%       │ ~165.9 MB   │ 15            │
└──────────────────────────────┴─────────────┴─────────────┴─────────────┴───────────────┘
```

#### Memory Hygiene Analysis:
* **Massive WebKit Reduction**: Prior WebKit-based architectures spawned helper processes (`WebKitWebProcess`, `com.apple.WebKit.GPU`), driving total RAM to ~280 MB. The pure native Swift rewrite maintains an RSS of **64–70 MB**, representing a 75% reduction in resident memory.
* **Leak Inspection**: Memory allocations remained stable across extended run cycles with zero runaway growth or retained window references.

### 4.2 The 1-Second Timer & Battery Impact
In [`Sources/SharedQuotaKit/Windowing/MenuBarManager.swift`](file:///Users/dad/git/antigravity-usage-monitor/Sources/SharedQuotaKit/Windowing/MenuBarManager.swift) (lines 78–82):

```swift
// Local 1-second countdown ticker for smooth UI updates
tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    Task { @MainActor in
        self?.decrementTickers()
    }
}
```

#### Performance Defect & Battery Pathology:
Every 1,000 milliseconds (1 Hz), `decrementTickers()`:
1. Iterates over all quota groups and models.
2. Re-allocates new `RateLimitWindow` and `ModelQuotaGroup` struct arrays.
3. Instantiates a new `UnifiedQuotaSnapshot`.
4. Mutates `self.viewModel.snapshot = updated`.
5. Re-renders the status item title and tooltip strings via `self.updateStatusItem()`.

Because `viewModel.snapshot` is an `@Published` property on an `ObservableObject`, **mutating it every second triggers SwiftUI view-graph invalidation and re-evaluation cycles, even when the popover and HUD window are completely hidden.**

* **Power Impact**: On Apple Silicon MacBooks running on battery power, uncoalesced 1-second timers prevent CPU cores from dropping into low-power idle states (Package C-states). Over an 8-hour workday, two companion utilities consuming ~1% CPU continuously will measurably shorten battery life.
* **Apple Energy Best Practice**: The 1-second countdown ticker is only visible to the user when the popover or detached HUD is actively displayed on screen. The menu bar title itself only formats minutes (`(4m)`), not seconds (unless $<60\text{s}$).

### 4.3 Network Polling Frequency Analysis
The network refresh timer is set to 30.0 seconds:
```swift
pollTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
    Task { @MainActor in
        self?.refreshData()
    }
}
```

* **Fleet-Wide Traffic Calculation**:
  * 1 developer workstation = 2 requests/min = 120 requests/hour = 2,880 requests/day.
  * In an engineering organization with **500 contributors**, this generates **1,440,000 requests/day** against Google's internal Cloud Code API.
* **Risk**: High-frequency synthetic traffic from corporate IP egress blocks risks triggering Cloud Code rate limiting, WAF throttling, or automated security alerts on developer accounts.
* **Recommendation**: Implement adaptive backoff: 30 seconds when the popover is active; back off to 120 seconds when closed; pause polling entirely when the workstation displays sleep or screensaver locks.

---

## 5. STRIDE Threat Model

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              STRIDE THREAT MODEL MATRIX                                │
├───────────────────┬───────────────────────────────────┬──────────┬──────────┬──────────┤
│ Threat Category   │ Vulnerability & Vector            │ Impact   │ Severity │ Status   │
├───────────────────┼───────────────────────────────────┼──────────┼──────────┼──────────┤
│ **Spoofing**      │ Local port 3007/3008 can be bound │ False    │ Medium   │ Mitigate │
│                   │ by rogue local process if daemon  │ Quota    │          │          │
│                   │ is stopped; unverified App Group. │ Display  │          │          │
├───────────────────┼───────────────────────────────────┼──────────┼──────────┼──────────┤
│ **Tampering**     │ Ad-hoc signed binary without      │ Malware  │ High     │ Fix      │
│                   │ Gatekeeper verification or        │ Injection│          │          │
│                   │ binary integrity protection.      │ / Mod    │          │          │
├───────────────────┼───────────────────────────────────┼──────────┼──────────┼──────────┤
│ **Repudiation**   │ Quota fetches omit cryptographic  │ Audit    │ Low      │ Accept   │
│                   │ signing or signed audit logs.     │ Gap      │          │          │
├───────────────────┼───────────────────────────────────┼──────────┼──────────┼──────────┤
│ **Information**   │ Unauthenticated 0.0.0.0 daemon    │ PII &    │ High     │ Fix      │
│ **Disclosure**    │ broadcasts user email, tier, and  │ Telemetry│          │          │
│                   │ usage metrics across local LAN.   │ Leak     │          │          │
├───────────────────┼───────────────────────────────────┼──────────┼──────────┼──────────┤
│ **Denial of**     │ 30s unbacked polling across 500+  │ Upstream │ Medium   │ Mitigate │
│ **Service**       │ machines risks triggering Cloud   │ Account  │          │          │
│                   │ Code WAF/IP blocks.               │ Lockout  │          │          │
├───────────────────┼───────────────────────────────────┼──────────┼──────────┼──────────┤
│ **Elevation of**  │ Unsandboxed process runs with     │ Full     │ High     │ Fix      │
│ **Privilege**     │ full user permissions; accesses   │ User     │          │          │
│                   │ default login keychain without UI.│ Access   │          │          │
└───────────────────┴───────────────────────────────────┴──────────┴──────────┴──────────┤
```

---

## 6. Corporate Deployment Roadmap & Enterprise Governance

To transition this application suite from its current **Pilot / Internal Developer** tier to an **Enterprise-Approved** software distribution, the engineering team must execute the following remediation roadmap across three distinct phases:

### Phase 1: Critical Security Remediations (Immediate)
1. **Enforce Localhost Binding Immediately**:
   Update `antigravity_usage_v5.py` to bind strictly to `127.0.0.1`. Remove `--bind 0.0.0.0` from all LaunchAgents and documentation. Terminate port 3007 exposure on external network interfaces.
2. **Implement Native Go-Keyring Unpacking in Swift**:
   Update [`Sources/AntigravityUsageApp/AntigravityDataProvider.swift`](file:///Users/dad/git/antigravity-usage-monitor/Sources/AntigravityUsageApp/AntigravityDataProvider.swift) to parse the `go-keyring-base64:` prefix, decode base64 data to JSON, and extract the active access token and refresh token:
   ```swift
   if tokenString.hasPrefix("go-keyring-base64:") {
       let cleanB64 = String(tokenString.dropFirst("go-keyring-base64:".count))
       if let decodedData = Data(base64Encoded: cleanB64),
          let json = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any],
          let token = json["access_token"] as? String {
           return token
       }
   }
   ```
3. **Implement Native Token Refresh**:
   Port the token refresh logic from `antigravity_usage_v5.py` (`refresh_access_token()`) directly into Swift `AntigravityDataProvider.swift` using `https://oauth2.googleapis.com/token`. This completely severs the dependency on the Python daemon.
4. **Throttle UI Timers**:
   Update `MenuBarManager.swift` so the 1-second ticker **only runs when `popover.isShown == true` or `hudPanel?.isVisible == true`**. When the UI is dismissed, pause the ticker entirely and update the menu bar title on the 30-second data poll.

### Phase 2: macOS Sandboxing & Code Signing (Pre-Deployment)
1. **Enable App Sandbox**:
   Update [`antigravity.entitlements`](file:///Users/dad/git/antigravity-usage-monitor/antigravity.entitlements) and `grok.entitlements` to include:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <true/>
   <key>com.apple.security.network.client</key>
   <true/>
   <key>com.apple.security.application-groups</key>
   <array>
       <string>$(TeamIdentifierPrefix)group.com.dad.aiusage</string>
   </array>
   ```
2. **Acquire Apple Developer ID & Notarize**:
   Replace ad-hoc signatures (`codesign -s -`) with an authoritative Apple Developer ID Application certificate. Submit binaries to Apple's Notary service (`xcrun notarytool submit`) to ensure Gatekeeper compliance across all managed corporate Macs.

### Phase 3: Enterprise Policy & Configuration Management
1. **Adaptive Polling & Energy Governance**:
   Implement dynamic polling intervals: 30s while actively viewing the HUD, 120s when minimized to the menu bar, and complete suspension when the system enters sleep or screen-lock.
2. **MDM Managed Preferences (`com.apple.ManagedClient`)**:
   Allow enterprise IT administrators to enforce corporate-wide defaults via MDM configuration profiles (`.mobileconfig`):
   * `DefaultRefreshInterval`: Enforce 60s or 120s across the fleet.
   * `AllowCrossDeviceServer`: Force-disable any local socket binding.
   * `MaskAccountIdentity`: Mask corporate email addresses in UI cards.

---

## 7. Verification Checklist for Corporate Sign-Off

- [ ] **Daemon Port Closed**: `netstat -an | grep 3007` returns empty or confirms loopback-only binding (`127.0.0.1.3007`).
- [ ] **Pure Native Swift Execution**: Both applications function with full quota reporting when the Python daemon process is killed.
- [ ] **Keychain Decoding Verified**: Native Swift extracts valid bearer tokens directly from `go-keyring-base64` structures without subprocess helpers.
- [ ] **Idle CPU Near Zero**: Menu bar app CPU drops to $<0.1\%$ when the popover is closed.
- [ ] **Code Signature Validated**: `spctl -a -vv -t install "/Applications/Antigravity Usage.app"` outputs `source=Notarized Developer ID`.
- [ ] **Zero Token Leakage in UserDefaults**: Verified that shared App Group plists contain only presentation metadata and no credentials.

---
*Report concluded and certified by Enterprise Security & Privacy Lead.*
