// Tests/TestRunner/main.swift
import Foundation
import SharedQuotaKit

func testTimerFormatting() {
    assert(formatShortTimer(seconds: 45) == "45s", "Failed 45s")
    assert(formatShortTimer(seconds: 900) == "15m", "Failed 15m")
    assert(formatShortTimer(seconds: 3720) == "1h 2m", "Failed 1h 2m")
    assert(formatShortTimer(seconds: 90000) == "1d 1h", "Failed 1d 1h")

    assert(formatRelativeTime(seconds: 0) == "Ready", "Failed Ready")
    assert(formatRelativeTime(seconds: 45) == "resets in 45s", "Failed 45s relative")
    assert(formatRelativeTime(seconds: 900) == "resets in 15m", "Failed 15m relative")
    assert(formatRelativeTime(seconds: 3720) == "resets in 1h 2m", "Failed 1h 2m relative")
    print("✓ PASS: testTimerFormatting")
}

func testSnapshotModelAndTitle() {
    let pLimit1 = RateLimitWindow(name: "5-Hour Limit", iconName: "clock", fraction: 0.51, resetsInSeconds: 240)
    let sLimit1 = RateLimitWindow(name: "Weekly Limit", iconName: "calendar", fraction: 0.91, resetsInSeconds: 340000)
    let grp1 = ModelQuotaGroup(title: "Gemini Models", subtitle: "Flash & Pro", primaryLimit: pLimit1, secondaryLimit: sLimit1)

    let pLimit2 = RateLimitWindow(name: "5-Hour Limit", iconName: "clock", fraction: 0.57, resetsInSeconds: 900)
    let sLimit2 = RateLimitWindow(name: "Weekly Limit", iconName: "calendar", fraction: 0.91, resetsInSeconds: 580000)
    let grp2 = ModelQuotaGroup(title: "Claude Models", subtitle: "Opus & Sonnet", primaryLimit: pLimit2, secondaryLimit: sLimit2)

    let snapshot = UnifiedQuotaSnapshot(
        brand: .antigravity,
        account: "test@example.com",
        tier: "Google AI Ultra",
        tierId: "g1-ultra-tier",
        description: "Test quotas",
        groups: [grp1, grp2]
    )

    assert(snapshot.menuBarTitle == "✦ G: 51% (4m) · C: 57% (15m)", "Menu bar title failed: \(snapshot.menuBarTitle)")
    print("✓ PASS: testSnapshotModelAndTitle (\(snapshot.menuBarTitle))")
}

func testAppGroupPersistenceSerialization() {
    let pLimit = RateLimitWindow(name: "Fast Limit", iconName: "bolt", fraction: 0.85, resetsInSeconds: 1200)
    let sLimit = RateLimitWindow(name: "Daily Limit", iconName: "calendar", fraction: 0.95, resetsInSeconds: 40000)
    let grp = ModelQuotaGroup(title: "Fast Models", subtitle: "Grok 2", primaryLimit: pLimit, secondaryLimit: sLimit)

    let snapshot = UnifiedQuotaSnapshot(
        brand: .grok,
        account: "grok_user",
        tier: "SuperGrok",
        tierId: "supergrok-tier",
        description: "xAI Quota",
        groups: [grp]
    )

    guard let data = try? JSONEncoder().encode(snapshot),
          let decoded = try? JSONDecoder().decode(UnifiedQuotaSnapshot.self, from: data) else {
        fatalError("Failed encoding/decoding snapshot")
    }

    assert(decoded.brand == .grok)
    assert(decoded.account == "grok_user")
    assert(decoded.tier == "SuperGrok")
    assert(decoded.groups.count == 1)
    assert(decoded.groups[0].primaryLimit.percentage == 85)
    print("✓ PASS: testAppGroupPersistenceSerialization")
}

print("==> Running SharedQuotaKit Test Suite...")
testTimerFormatting()
testSnapshotModelAndTitle()
testAppGroupPersistenceSerialization()
print("==> All 3 Tests PASSED Successfully!")
