// SharedModels/SharedQuota.swift
// v1 – Shared quota data models for Antigravity Usage Monitor and Widget extension
import Foundation

public struct SharedQuotaSnapshot: Codable {
    public let account: String
    public let tier: String
    public let tierId: String
    public let quotaPercent: Int
    public let primaryModel: String
    public let primaryPercent: Int
    public let primaryResetsIn: Int?
    public let lastUpdated: Date

    public init(
        account: String,
        tier: String,
        tierId: String,
        quotaPercent: Int,
        primaryModel: String,
        primaryPercent: Int,
        primaryResetsIn: Int?,
        lastUpdated: Date = Date()
    ) {
        self.account = account
        self.tier = tier
        self.tierId = tierId
        self.quotaPercent = quotaPercent
        self.primaryModel = primaryModel
        self.primaryPercent = primaryPercent
        self.primaryResetsIn = primaryResetsIn
        self.lastUpdated = lastUpdated
    }
}
