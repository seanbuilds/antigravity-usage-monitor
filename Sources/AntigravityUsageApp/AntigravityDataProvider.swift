// Sources/AntigravityUsageApp/AntigravityDataProvider.swift
import Foundation
import SharedQuotaKit

public struct AntigravityDataProvider: QuotaDataProvider {
    public let brand: BrandIdentity = .antigravity

    public init() {}

    public func fetchQuota() async throws -> UnifiedQuotaSnapshot {
        // Priority 1: Check local daemon endpoint if running (sub-5ms)
        if let localData = await tryFetchLocalEndpoint() {
            return localData
        }

        // Priority 2: Direct Keychain token extraction & Cloud Code API query
        return try await fetchFromCloudCodeAPI()
    }

    private func tryFetchLocalEndpoint() async -> UnifiedQuotaSnapshot? {
        guard let url = URL(string: "http://127.0.0.1:3007/quota") else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try parseCloudCodeJSON(data)
        } catch {
            return nil
        }
    }

    private func fetchFromCloudCodeAPI() async throws -> UnifiedQuotaSnapshot {
        // Look up OAuth token in Keychain
        guard let token = KeychainHelper.readPassword(service: "gemini", account: "antigravity") else {
            throw NSError(domain: "AntigravityDataProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "No Antigravity credential found in Keychain"])
        }

        guard let url = URL(string: "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary") else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("antigravity/1.0", forHTTPHeaderField: "User-Agent")
        req.httpBody = "{}".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try parseCloudCodeJSON(data)
    }

    private func parseCloudCodeJSON(_ data: Data) throws -> UnifiedQuotaSnapshot {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let account = json["account"] as? String ?? "Active Account"
        let tier = json["tier"] as? String ?? "Google AI Ultra"
        let tierId = json["tierId"] as? String ?? "g1-ultra-tier"
        let desc = json["description"] as? String ?? "Proportional shared model quotas"

        var modelGroups = [ModelQuotaGroup]()

        if let groups = json["groups"] as? [[String: Any]] {
            for grp in groups {
                let dName = grp["displayName"] as? String ?? "Models"
                let gDesc = grp["description"] as? String ?? ""
                var primaryLimit: RateLimitWindow?
                var secondaryLimit: RateLimitWindow?

                if let buckets = grp["buckets"] as? [[String: Any]] {
                    for b in buckets {
                        let w = b["window"] as? String ?? ""
                        let frac = b["remainingFraction"] as? Double ?? 1.0
                        let resetTime = b["resetTime"] as? String
                        let resetsIn = b["resetsInSeconds"] as? Int ?? parseSecondsRemaining(from: resetTime)

                        let limit = RateLimitWindow(
                            name: w == "5h" ? "5-Hour Rolling Limit" : "Weekly Plan Quota",
                            iconName: w == "5h" ? "clock.arrow.circlepath" : "calendar",
                            fraction: frac,
                            resetsInSeconds: resetsIn,
                            resetTime: resetTime
                        )

                        if w == "5h" {
                            primaryLimit = limit
                        } else {
                            secondaryLimit = limit
                        }
                    }
                }

                let p = primaryLimit ?? RateLimitWindow(name: "5-Hour Rolling Limit", iconName: "clock", fraction: 1.0, resetsInSeconds: nil)
                let s = secondaryLimit ?? RateLimitWindow(name: "Weekly Plan Quota", iconName: "calendar", fraction: 1.0, resetsInSeconds: nil)
                modelGroups.append(ModelQuotaGroup(title: dName, subtitle: gDesc, primaryLimit: p, secondaryLimit: s))
            }
        }

        return UnifiedQuotaSnapshot(
            brand: .antigravity,
            account: account,
            tier: tier,
            tierId: tierId,
            description: desc,
            groups: modelGroups
        )
    }

    private func parseSecondsRemaining(from resetTime: String?) -> Int? {
        guard let timeStr = resetTime, !timeStr.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var targetDate = iso.date(from: timeStr)
        if targetDate == nil {
            iso.formatOptions = [.withInternetDateTime]
            targetDate = iso.date(from: timeStr)
        }
        guard let date = targetDate else { return nil }
        let diff = Int(date.timeIntervalSinceNow)
        return diff > 0 ? diff : nil
    }
}
