<!-- v1 – Creative Researcher Consumer Review -->
# Consumer Review: Antigravity & Grok Usage Monitor Suite
**Perspective:** The Multi-Model Creative & Research Writer  
**Reviewed Components:** Antigravity Usage Monitor (`Antigravity Usage.app`), Grok Usage Monitor (`Grok Usage.app`), `SharedQuotaKit`, and Native WidgetKit Extensions  
**Software Foundation:** Pure Native Swift / SwiftUI / AppKit Suite (macOS Sonoma 14.0+)  
**Repository Location:** `/Users/dad/git/antigravity-usage-monitor/`  
**Evaluation Date:** September 14, 2026  

---

## 🖋 Reviewer Persona & Workflow Context

As an analytical research and creative non-fiction writer, my daily work involves synthesizing thousands of pages of academic literature, primary historical archives, and dense analytical papers into cohesive, long-form narratives and monograph chapters. 

My writing environment relies on a dual-engine workflow:
* **Google Antigravity (Claude Opus & Claude Sonnet, augmented by Gemini Pro)**: My core intellectual sparring partner and developmental editor. I rely on Claude Opus for deep structural synthesis, dialectical stress-testing, and nuanced prose refinement where cadence, tone, and logical progression are paramount.
* **xAI Grok (SuperGrok Heavy)**: My divergent discovery and brainstorming partner. I use Grok for real-time web discovery, uncovering fresh discourse on X, generating contrarian angles, and using Grok Imagine to produce atmospheric imagery for world-building and visual research prompts.

### The Creative Writer's Dilemma: Flow State vs. Limit Anxiety
Deep writing demands sustained flow state. When revising an 8,000-word chapter with Claude Opus, a sudden, opaque model cutoff ("Rate limit reached, try again later") is mentally catastrophic. It halts creative momentum, fractures concentration, and induces rationing anxiety: *Can I ask one more clarifying question, or will my session freeze for the next four hours?*

For a non-developer writer, opening a command-line terminal or parsing cryptic HTTP error codes is out of the question. I need ambient, glanceable, aesthetically refined visibility into my exact creative runway. This review evaluates the Antigravity & Grok Usage Monitor suite specifically through that lens: **Does this tool suite protect my creative focus, demystify model allocations, and fit seamlessly into a writer's workspace?**

---

## 🌟 Executive Summary & Scorecard

The Antigravity & Grok Usage Monitor suite is an exceptional, calm-technology utility that transforms opaque cloud model constraints into actionable, glanceable peace of mind. By discarding heavy browser wrappers in favor of a 100% native Swift and AppKit architecture, the applications sit weightlessly in the macOS menu bar, consuming trivial memory while delivering instantaneous feedback.

The inclusion of live 1-second decrementing countdown timers (`[resets in 2h 5m]`, `[resets in 15m]`), high-contrast Obsidian dark cards, and a detachable floating HUD panel elevates this from a utility into an indispensable creative companion.

```
┌────────────────────────────────────────────────────────────────────────┐
│                         WRITER'S SCORECARD                             │
├───────────────────────────────────────┬────────────┬───────────────────┤
│ Evaluation Dimension                  │ Score      │ Verdict           │
├───────────────────────────────────────┼────────────┼───────────────────┤
│ 1. Cognitive Load & Visual Hierarchy  │ 9.6 / 10   │ Exemplary Calm UI │
│ 2. Dual Rate-Limit Comprehension      │ 9.2 / 10   │ Highly Intuitive  │
│ 3. Cross-Tool Consistency             │ 9.5 / 10   │ Harmonious Suite  │
│ 4. Desktop Widget & HUD Ergonomics    │ 9.8 / 10   │ Flow-Preserving   │
│ 5. Setup & Credential Handling        │ 9.9 / 10   │ Pure Zero-Config  │
├───────────────────────────────────────┴────────────┴───────────────────┤
│ Overall Power-User Writer Rating: 9.6 / 10 (Editor's Choice)          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Cognitive Load & Visual Hierarchy: The Obsidian Canvas

### The Aesthetics of Deep Work
Writers are notoriously sensitive to visual clutter. The monitor's aesthetic design—built on a dark Obsidian palette (`#0D1017`) layered over macOS native AppKit window material (`.hudWindow` with subtle system vibrancy)—is a visual triumph.

* **Non-Intrusive Contrast:** In a dim writing room or during late-night drafting sessions in Scrivener or Ulysses, brightly lit dialog boxes cause eye strain and pull the eye away from the manuscript. The Obsidian card styling with delicate semi-transparent white borders (`Color.white.opacity(0.08)`) feels sophisticated, muted, and respectful of the user's attention.
* **Typography & Legibility:** Using Apple's SF Pro Rounded for numerals paired with clean system weights provides instant legibility at a distance. When glancing up from a manuscript, the percentage indicator (`80%`, `100%`) can be absorbed in under 200 milliseconds without reading a single word of text.
* **Tri-Color Gradient Progress Bars:** The adaptive color logic provides intuitive risk assessment:
  * **Emerald Green (`≥50%`):** Abundant creative runway. Feel free to run multi-turn Opus revisions.
  * **Warm Amber (`20% – 49%`):** Pacing zone. Begin prioritizing queries or transition to Sonnet for lighter drafting.
  * **Crimson Red (`<20%`):** Critical depletion. Reserve remaining queries strictly for final polishing.

### Plan Tier Badges: Eliminating Subscription Ambiguity
A persistent frustration with modern AI providers is tier obfuscation. Default provider web consoles frequently display generic labels or obscure fallback codes. 

In this monitor suite, verified tier badges are showcased with prominent visual dignity:
* **`Google AI Ultra` (`[ULTRA]`):** Displayed as an amber-gold pill badge (`Color(red: 1.0, green: 0.84, blue: 0.04)`), immediately confirming that the session is operating under Google's premier consumer tier with top-priority quota ceilings.
* **`SuperGrok Heavy` (`[SUPERGROK]`):** Displayed in crisp monochrome silver, verifying that the session has access to xAI's high-capacity reasoning tier (Tier 5) with priority queuing.

For an analytical consumer paying premium monthly subscription fees, this unambiguous confirmation provides continuous reassurance that their accounts are authenticated and receiving full service entitlements.

### Jargon-Free Information Architecture
The layout avoids developer-centric terms like "concurrency slots", "HTTP 429 backoff", or "token bucket leaky integrators". Instead, the interface organizes information into clean, logical hierarchies:
1. **Header:** Brand icon, application title, and subscription tier badge.
2. **Model Families:** Grouped into clear categories—*Gemini Models* (Flash, Pro) and *Claude and GPT models* (Opus, Sonnet, GPT-OSS).
3. **Card Metrics:** Clear labels denoting the time horizon (*5-Hour Rolling Limit* and *Weekly Plan Quota*).
4. **Footer:** Active authenticated user profile and a clean, quiet exit button.

Crucially, technical diagnostic data (such as local port bindings, account hashes, and raw timestamps) is cleanly sequestered behind a subtle gear icon (`⌘,`), ensuring the primary view remains entirely free of cognitive noise.

---

## 2. Dual Rate-Limit Comprehension: Sprint Runway vs. Fuel Reserve

### Solving the Dual-Horizon Mental Model
The most conceptually challenging aspect of Google Antigravity for everyday writers is the coexistence of two independent rate limits:
1. **The 5-Hour Rolling Smoothing Limit**
2. **The Weekly Plan Quota**

Before using this monitor, I frequently encountered confusion: *“My account says I have 90% of my monthly quota remaining, so why is Claude refusing to answer my prompt?”* 

The monitor solves this mental disconnect through deliberate spatial separation:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        MODEL ALLOCATION CARD                           │
├────────────────────────────────────────────────────────────────────────┤
│  Claude and GPT models                                                 │
│  Models within this group: Claude Opus, Claude Sonnet, GPT-OSS         │
│                                                                        │
│  [clock]  5-Hour Rolling Limit          [Ready]                   100% │
│  [===================================================================] │
│                                                                        │
│  [cal]    Weekly Plan Quota             [resets in 6d 16h]         91% │
│  [==============================================================.....] │
└────────────────────────────────────────────────────────────────────────┘
```

By displaying both meters vertically inside a single card:
* The writer immediately understands that the **5-Hour Rolling Limit** is their **Sprint Runway**—a short-term burst buffer designed to prevent service overload during intense sessions.
* The **Weekly Plan Quota** is their **Fuel Tank**—the total volume of tokens granted by their subscription tier for the seven-day billing period.

### Psychological Relief of Live Countdown Badges
When a writer does push hard during an intensive research sprint and depletes their 5-hour burst window, the difference between an opaque error and a live countdown timer is transformative:

* **Opaque Platform Error:** Induces frustration, uncertainty, and friction. The writer does not know if they must wait 10 minutes or 4 hours, breaking their daily schedule.
* **Live Countdown Pill Badge (`[resets in 15m]` / `[resets in 2h 5m]`):** Restores agency. A badge indicating `[resets in 25m]` prompts a natural pause: get up, brew a fresh cup of tea, stretch, and outline the next argument by hand on paper. 

Because the native Swift application (`app_main_v12.swift` and `MenuBarManager.swift`) updates its countdown timer every single second in memory without sending network pings, the time decrements smoothly and reliably before your eyes. It feels alive, honest, and reassuring.

---

## 3. Cross-Tool Consistency: Antigravity vs. Grok

In a multi-model writing workflow, switching between applications must feel fluid. Disjointed tools with conflicting visual languages introduce subtle cognitive fatigue. The Antigravity & Grok monitor suite addresses this through a shared software foundation (`SharedQuotaKit`).

```
┌────────────────────────────────────────────────────────────────────────┐
│                    CROSS-APPLICATION HARMONY MATRIX                    │
├───────────────────────┬───────────────────────┬────────────────────────┤
│ Attribute             │ Antigravity Usage     │ Grok Usage             │
├───────────────────────┼───────────────────────┼────────────────────────┤
│ Menu Bar Mark         │ ✦ (Electric Sparkle)  │ ⊘ (Minimalist Slash)   │
│ Accent Palette        │ Deep Sapphire Blue    │ Polar Silver / Slate   │
│ Menu Bar Reading      │ ✦ G: 80% · C: 100%    │ ⊘ 84% (6d 2h)          │
│ Verified Tier Badge   │ [ULTRA] (Gold)        │ [SUPERGROK] (Silver)   │
│ Primary Focus         │ Multi-Model Dual Time │ Weekly Quota + Credits │
│ Secondary Metrics     │ Gemini vs Claude/GPT  │ Image & Build Usage    │
│ Detachable HUD Panel  │ Yes (⌘U)              │ Yes (⌘U)               │
│ Keyboard Shortcuts    │ ⌘R, ⌘U, ⌘W, ⌘Q        │ ⌘R, ⌘U, ⌘W, ⌘Q         │
│ Window Width          │ 360 pt (Uniform)      │ 360 pt (Uniform)       │
└───────────────────────┴───────────────────────┴────────────────────────┘
```

### Visual and Behavioral Parity
* **Card Dimensions & Spacing:** Both popovers measure exactly 360 points wide, maintaining identical margins (14pt outer padding, 10–12pt card corner radiuses). When toggling between them on the menu bar, the transition feels like consulting two tabs within a master control suite.
* **Interactive Shortcuts:** Muscle memory remains intact across both applications. Pressing `⌘U` detaches either popover into a floating desk HUD; pressing `⌘R` triggers a synchronized data refresh with a smooth 360° rotational icon animation.
* **Domain Adaptation:** While the shell is unified, each tool adapts to its provider’s specific billing reality:
  * **Antigravity** highlights the critical dual-rate limit matrix between first-party models (Gemini) and third-party partner models (Claude Opus/Sonnet).
  * **Grok** presents weekly remaining capacity alongside prepaid on-demand credits (e.g., 976 credits) and a service breakdown detailing image generation (`Grok Imagine: 15%`) versus agentic coding tasks (`Grok Build: 1%`).

This differentiation is purposeful: it reflects the actual commercial mechanics of each AI service while maintaining a single, coherent user experience.

---

## 4. Desktop Widget & Floating HUD Experience

### The Value of Ambient Visibility During Long Drafting Sprints
When immersed in writing 15 pages of complex exposition, moving the mouse to the top corner of the screen to click a menu bar icon is an active context switch. It interrupts physical typing flow.

The monitor suite addresses this through two distinct ambient presentation surfaces:

#### 1. The Detachable Floating HUD (`⌘U`)
By clicking the unsnap icon or pressing `⌘U`, the menu bar popover detaches into a freestanding, frameless AppKit panel (`HUDPanel.swift`). 
* **Always-On-Top Layering (`.floating`):** Can be positioned in the corner of a secondary monitor or beside an active Scrivener window.
* **Screen Coordinate Awareness:** Automatically identifies the display where the cursor resides and clamps window geometry inside visible bounds, ensuring it never gets lost behind screen notches or off-screen borders.
* **Subtle Presence:** Because it utilizes translucent visual effect materials, it feels like an ambient instrument cluster rather than a distracting utility window.

#### 2. Native macOS WidgetKit Widgets (`systemSmall` & `systemMedium`)
For writers who prefer a clean screen free of floating windows, the native WidgetKit extensions (`AntigravityWidget` and `GrokWidget`) bring status information directly to the macOS Notification Center or Desktop Canvas:
* **Large Glanceable Percentage:** The small widget features a bold 28pt numeral with dynamic health coloring (green, yellow, red), displaying current capacity at a glance.
* **Zero Active CPU Consumption:** Powered by macOS timeline entries that refresh quietly via sandboxed App Group persistence (`group.com.dad.aiusage`).
* **Timestamp Reassurance:** Displays the exact minute of the last background update, giving the writer certainty that the numbers reflect real-time ground truth.

---

## 5. Ground Truth Verification & Credential Security

To ensure this review is grounded in verified system reality rather than theoretical claims, I inspected the live endpoints, authentication payloads, and security mechanisms active on this machine.

### Live Payload Audit
Inspecting the live endpoints confirmed exact operational synchronization:

#### Antigravity Quota Daemon (`http://127.0.0.1:3007/quota`):
```json
{
  "account": "ohheysean@gmail.com",
  "tier": "Google AI Ultra",
  "tierId": "g1-ultra-tier",
  "tierDescription": "You are subscribed to the best Google AI plan.",
  "groups": [
    {
      "displayName": "Gemini Models",
      "buckets": [
        { "bucketId": "gemini-weekly", "remainingFraction": 0.9016, "resetsInSeconds": 328089 },
        { "bucketId": "gemini-5h", "remainingFraction": 0.8073, "resetsInSeconds": 7536 }
      ]
    },
    {
      "displayName": "Claude and GPT models",
      "buckets": [
        { "bucketId": "3p-weekly", "remainingFraction": 0.9146, "resetsInSeconds": 577076 },
        { "bucketId": "3p-5h", "remainingFraction": 1.0, "resetsInSeconds": 17991 }
      ]
    }
  ]
}
```
* **Ground Truth Verification:** Confirms active subscription tier `Google AI Ultra` (`g1-ultra-tier`). The 5-hour rolling limit for Claude and GPT models currently sits at `100%`, indicating complete readiness for an intensive Opus synthesis sprint.

#### Grok Quota Endpoint (`http://127.0.0.1:3008/quota`):
```json
{
  "account": "sean.tyler@me.com",
  "name": "Sun Glasses",
  "tier": "SuperGrok Heavy",
  "tierLevel": 5,
  "quota": {
    "usagePercent": 16.0,
    "remainingPercent": 84.0,
    "prepaidCredits": 976,
    "resetsInSeconds": 525525
  },
  "products": [
    { "name": "Grok Imagine", "usagePercent": 15.0 },
    { "name": "Grok Build", "usagePercent": 1.0 },
    { "name": "Grok Chat", "usagePercent": 0.0 }
  ]
}
```
* **Ground Truth Verification:** Confirms `SuperGrok Heavy` (Tier 5) with `84%` remaining weekly quota and `976` prepaid credits. Product breakdown reveals `15%` consumption in Grok Imagine, reflecting recent visual ideation prompts.

### Zero-Friction Credential Security
For non-technical creative professionals, dealing with environment variables, API secret keys, and `.env` files is a major barrier to entry.

The monitor suite handles authentication with complete invisibility:
1. **Antigravity:** Directly queries the macOS Keychain for the system OAuth token stored by the local Antigravity environment (`security find-generic-password -s gemini -a antigravity`).
2. **Grok:** Inspects the authenticated user profile in `~/.grok/auth.json` or Keychain without prompting for passwords or API tokens.
3. **Local Loopback Isolation:** All communication occurs over loopback ports (`127.0.0.1:3007` and `3008`), ensuring no private usage metadata leaves the physical Mac hardware.

This means zero configuration on day one: launch the application, and it immediately functions without a single setup wizard or configuration dialog.

---

## 6. Delight Moments & Constructive Suggestions

### Moments of Consumer Delight
1. **The Fluid Popover Unsnap:** Clicking `⌘U` to transform a static menu bar dropdown into a floating HUD that can be dragged directly beside my manuscript editor feels like magic. It demonstrates deep empathy for how writers actually use screen space.
2. **The 1-Second Countdown Ticker:** Watching `resets in 2h 5m` decrement to `resets in 2h 4m` while drafting gives a palpable sense of time moving forward, reassuring me that the clock is ticking toward a full quota refresh.
3. **Double Status in the Menu Bar:** The compact status reading `✦ G: 80% · C: 100%` conveys total system health in fewer than 20 characters of menu bar real estate.
4. **Instant Diagnostic Transparency:** Hitting `⌘,` to review daemon latency, IP binding, and account verification satisfies the analytical mind without cluttering daily writing sessions.

### Opportunities for Enhancement & Clarification
While the suite is exceptionally polished, several refinements would make it even more welcoming to non-developer writers:

1. **Token Cost & Model Weighting Clarification:**
   * *Observation:* Claude Opus consumes quota at a significantly faster rate than Claude Sonnet, yet both share the single `Claude and GPT models` pool.
   * *Recommendation:* Add an understated footnote or hover tip inside the card:  
     *“Claude Opus consumes proportional limit faster than Sonnet. For quick drafting, use Sonnet to preserve burst runway.”*
2. **Human-Centered Label Alternatives:**
   * *Observation:* "5-Hour Rolling Limit" accurately describes the technical window, but "Rolling Limit" sounds slightly clinical.
   * *Recommendation:* In consumer mode, consider labeling it **"5-Hour Sprint Limit"** or **"Active Sprint Runway"**, paired with **"Weekly Capacity"**. This reinforces the mental model of short-term pacing versus long-term reserve.
3. **Proactive Flow-State Notifications:**
   * *Observation:* Currently, the writer must glance at the status item or HUD to notice that quota is running low.
   * *Recommendation:* Introduce an optional, gentle macOS notification when remaining 5-hour capacity drops below `20%`:  
     *“✦ Antigravity: 18% sprint runway remaining for Claude. Consider wrapping up structural revisions or pacing prompts.”*
4. **Unified Multi-Brand Menu Bar Mode:**
   * *Observation:* Running both `Antigravity Usage.app` and `Grok Usage.app` places two separate icons on the menu bar (`✦` and `⊘`). On smaller MacBooks with a camera notch, menu bar real estate is precious.
   * *Recommendation:* Offer an optional consolidated mode where a single unified status bar icon (e.g., `✦ 80% · ⊘ 84%`) opens a combined tabbed card displaying both providers side-by-side.

---

## 7. Final Verdict

The Antigravity & Grok Usage Monitor suite is an outstanding example of purposeful, quiet software design. It takes an anxiety-inducing constraint of modern creative work—the opaque, variable rate limits of frontier AI reasoning models—and renders it transparent, predictable, and aesthetically pleasing.

For creative writers, researchers, and analytical thinkers who treat AI models not as toys but as serious intellectual collaborators, this tool suite removes the guesswork and protects the flow state. It belongs in the menu bar of every serious long-form writer working on macOS.

**Final Consumer Power-User Rating: 9.6 / 10**  
*Highly Recommended for Research Writers, Essayists, and Multi-Model Authors.*
