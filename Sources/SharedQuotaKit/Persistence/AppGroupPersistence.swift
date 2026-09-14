// Sources/SharedQuotaKit/Persistence/AppGroupPersistence.swift
import Foundation

public final class AppGroupPersistence: @unchecked Sendable {
    public static let shared = AppGroupPersistence()
    public let appGroupID = "group.com.dad.aiusage"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    public func saveSnapshot(_ snapshot: UnifiedQuotaSnapshot) {
        guard let defs = defaults else { return }
        let keyPrefix = snapshot.brand.appGroupKey

        defs.set(snapshot.tier, forKey: "\(keyPrefix).tier")
        defs.set(snapshot.account, forKey: "\(keyPrefix).account")
        defs.set(snapshot.lastUpdated, forKey: "\(keyPrefix).lastUpdated")

        if let firstGroup = snapshot.groups.first {
            defs.set(firstGroup.primaryLimit.percentage, forKey: "\(keyPrefix).quotaPercent")
            defs.set(firstGroup.primaryLimit.resetsInSeconds ?? 0, forKey: "\(keyPrefix).resetsIn")
        }

        if let encoded = try? JSONEncoder().encode(snapshot) {
            defs.set(encoded, forKey: "\(keyPrefix).snapshot")
        }
    }

    public func loadSnapshot(for brand: BrandIdentity) -> UnifiedQuotaSnapshot? {
        guard let defs = defaults,
              let data = defs.data(forKey: "\(brand.appGroupKey).snapshot"),
              let decoded = try? JSONDecoder().decode(UnifiedQuotaSnapshot.self, from: data) else {
            return nil
        }
        return decoded
    }
}
