// Sources/SharedQuotaKit/Protocols/DataProviderProtocol.swift
import Foundation

public protocol QuotaDataProvider: Sendable {
    var brand: BrandIdentity { get }
    func fetchQuota() async throws -> UnifiedQuotaSnapshot
}
