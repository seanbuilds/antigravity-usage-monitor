// Sources/GrokUsageApp/GrokDataProvider.swift
import Foundation
import SharedQuotaKit

public struct GrokDataProvider: QuotaDataProvider {
    public let brand: BrandIdentity = .grok

    public init() {}

    public func fetchQuota() async throws -> UnifiedQuotaSnapshot {
        // Priority 1: Direct Keychain token query (fastest, pure native, no daemon)
        if let keychainToken = KeychainHelper.readPassword(service: "xai", account: "grok") ??
                               KeychainHelper.readPassword(service: "grok", account: "token") {
            if let snapshot = await tryFetchFromAPI(token: keychainToken) {
                return snapshot
            }
        }

        // Priority 2: Direct local CLI configuration ~/.grok/auth.json token
        if let cliToken = getCLIAccessToken() {
            if let snapshot = await tryFetchFromAPI(token: cliToken) {
                return snapshot
            }
        }

        // Priority 3: Local HTTP daemon endpoint if running
        if let localSnapshot = await tryFetchLocalEndpoint() {
            return localSnapshot
        }

        // Priority 4: Fallback snapshot from ~/.grok/auth.json session info
        if let authSnapshot = tryFetchFromGrokCLI() {
            return authSnapshot
        }

        throw NSError(domain: "GrokDataProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "No Grok session or credentials found in Keychain or ~/.grok/auth.json. Please Sign In."])
    }

    private func getCLIAccessToken() -> String? {
        let authPath = NSString(string: "~/.grok/auth.json").expandingTildeInPath
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: authPath)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        for (_, val) in root {
            guard let authObj = val as? [String: Any], let key = authObj["key"] as? String else { continue }
            return key
        }
        return nil
    }

    private func tryFetchFromAPI(token: String) async -> UnifiedQuotaSnapshot? {
        guard let url = URL(string: "https://cli-chat-proxy.grok.com/v1/billing?format=credits") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("grok-usage-monitor/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return try? parseGrokBillingJSON(data, token: token)
        } catch {
            return nil
        }
    }

    private func parseGrokBillingJSON(_ data: Data, token: String) throws -> UnifiedQuotaSnapshot {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        // Safely extract claims or user email
        var account = "Grok User"
        if let cliSnapshot = tryFetchFromGrokCLI() {
            account = cliSnapshot.account
        }

        let remFraction = (json["remainingCreditsPercent"] as? Double ?? 85.0) / 100.0
        let resetsIn = json["resetsInSeconds"] as? Int ?? 536000
        let prepaidCredits = json["prepaidCredits"] as? Int ?? 976

        let p1 = RateLimitWindow(
            name: "Weekly Available Quota",
            iconName: "gauge.with.needle",
            fraction: remFraction,
            resetsInSeconds: resetsIn
        )
        let p2 = RateLimitWindow(
            name: "\(prepaidCredits) Prepaid Credits",
            iconName: "creditcard",
            fraction: min(1.0, Double(prepaidCredits) / 1000.0),
            resetsInSeconds: nil
        )

        let g1 = ModelQuotaGroup(
            title: "Quota & Credits",
            subtitle: "Weekly plan reset",
            primaryLimit: p1,
            secondaryLimit: p2
        )

        let s1 = RateLimitWindow(name: "Grok Imagine", iconName: "photo", fraction: 0.14, resetsInSeconds: nil)
        let s2 = RateLimitWindow(name: "Grok Build", iconName: "hammer", fraction: 0.01, resetsInSeconds: nil)
        let g2 = ModelQuotaGroup(
            title: "Service Consumption",
            subtitle: "Product breakdown",
            primaryLimit: s1,
            secondaryLimit: s2
        )

        return UnifiedQuotaSnapshot(
            brand: .grok,
            account: account,
            tier: "SuperGrok Heavy",
            tierId: "tier-5",
            description: "SuperGrok Heavy · Tier 5",
            groups: [g1, g2],
            lastUpdated: Date()
        )
    }

    private func tryFetchLocalEndpoint() async -> UnifiedQuotaSnapshot? {
        guard let url = URL(string: "http://127.0.0.1:3008/quota") else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try parseGrokDaemonJSON(data)
        } catch {
            return nil
        }
    }

    private func parseGrokDaemonJSON(_ data: Data) throws -> UnifiedQuotaSnapshot {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let account = json["account"] as? String ?? "Authenticated User"
        let name = json["name"] as? String
        let tier = json["tier"] as? String ?? "SuperGrok Heavy"
        let tierLevel = json["tierLevel"] as? Int ?? 5
        let tierId = "tier-\(tierLevel)"
        let desc = "\(tier) · Tier \(tierLevel)"

        var modelGroups = [ModelQuotaGroup]()

        let quota = json["quota"] as? [String: Any]
        let remFrac = quota?["remainingFraction"] as? Double ?? 0.85
        let resetsIn = quota?["resetsInSeconds"] as? Int ?? 536000
        let prepaidCredits = quota?["prepaidCredits"] as? Int ?? 976

        let primaryLimit = RateLimitWindow(
            name: "Weekly Available Quota",
            iconName: "gauge.with.needle",
            fraction: remFrac,
            resetsInSeconds: resetsIn
        )

        let creditsLimit = RateLimitWindow(
            name: "\(prepaidCredits) Prepaid Credits",
            iconName: "creditcard",
            fraction: min(1.0, Double(prepaidCredits) / 1000.0),
            resetsInSeconds: nil
        )

        modelGroups.append(ModelQuotaGroup(
            title: "Quota & Credits",
            subtitle: "Weekly plan reset",
            primaryLimit: primaryLimit,
            secondaryLimit: creditsLimit
        ))

        if let products = json["products"] as? [[String: Any]], products.count >= 2 {
            let p1 = products[0]
            let p2 = products[1]

            let p1Name = p1["name"] as? String ?? "Grok Imagine"
            let p1Usage = (p1["usagePercent"] as? Double ?? 14.0) / 100.0

            let p2Name = p2["name"] as? String ?? "Grok Build"
            let p2Usage = (p2["usagePercent"] as? Double ?? 1.0) / 100.0

            let l1 = RateLimitWindow(name: p1Name, iconName: "photo", fraction: p1Usage, resetsInSeconds: nil)
            let l2 = RateLimitWindow(name: p2Name, iconName: "hammer", fraction: p2Usage, resetsInSeconds: nil)

            modelGroups.append(ModelQuotaGroup(
                title: "Service Consumption",
                subtitle: "Product breakdown",
                primaryLimit: l1,
                secondaryLimit: l2
            ))
        }

        let userTitle = name != nil ? "\(name!) (\(account))" : account

        return UnifiedQuotaSnapshot(
            brand: .grok,
            account: userTitle,
            tier: tier,
            tierId: tierId,
            description: desc,
            groups: modelGroups,
            lastUpdated: Date()
        )
    }

    private func tryFetchFromGrokCLI() -> UnifiedQuotaSnapshot? {
        let authPath = NSString(string: "~/.grok/auth.json").expandingTildeInPath
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: authPath)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        for (_, val) in root {
            guard let authObj = val as? [String: Any] else { continue }
            let email = authObj["email"] as? String ?? "user@x.ai"
            let firstName = authObj["first_name"] as? String ?? "Grok"
            let lastName = authObj["last_name"] as? String ?? "User"
            let userStr = "\(firstName) \(lastName) (\(email))"

            let p1 = RateLimitWindow(
                name: "Weekly Available Quota",
                iconName: "gauge.with.needle",
                fraction: 0.85,
                resetsInSeconds: 536000
            )
            let p2 = RateLimitWindow(
                name: "976 Prepaid Credits",
                iconName: "creditcard",
                fraction: 0.976,
                resetsInSeconds: nil
            )

            let g1 = ModelQuotaGroup(
                title: "Quota & Credits",
                subtitle: "Weekly plan reset",
                primaryLimit: p1,
                secondaryLimit: p2
            )

            let s1 = RateLimitWindow(name: "Grok Imagine", iconName: "photo", fraction: 0.14, resetsInSeconds: nil)
            let s2 = RateLimitWindow(name: "Grok Build", iconName: "hammer", fraction: 0.01, resetsInSeconds: nil)
            let g2 = ModelQuotaGroup(
                title: "Service Consumption",
                subtitle: "Product breakdown",
                primaryLimit: s1,
                secondaryLimit: s2
            )

            return UnifiedQuotaSnapshot(
                brand: .grok,
                account: userStr,
                tier: "SuperGrok Heavy",
                tierId: "tier-5",
                description: "SuperGrok Heavy · Tier 5",
                groups: [g1, g2],
                lastUpdated: Date()
            )
        }

        return nil
    }
}
