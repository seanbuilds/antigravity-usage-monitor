// Sources/SharedQuotaKit/Security/WebAuthManager.swift
import Foundation
import AuthenticationServices
import AppKit

@MainActor
public final class WebAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = WebAuthManager()

    private var authSession: ASWebAuthenticationSession?

    // Grok / xAI OAuth Constants
    public static let grokClientID = "b1a00492-073a-47ea-816f-4c329264a828"
    public static let grokTokenEndpoint = "https://auth.x.ai/oauth2/token"
    public static let grokAuthEndpoint = "https://auth.x.ai/oauth2/auth"
    public static let callbackScheme = "grokquota"

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first ?? NSWindow()
    }

    /// Launches native ASWebAuthenticationSession to authenticate user with xAI / Grok
    public func startGrokWebAuth() async throws -> String {
        let redirectURI = "\(Self.callbackScheme)://oauth-callback"
        var components = URLComponents(string: Self.grokAuthEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.grokClientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "openid profile email offline_access")
        ]

        guard let authURL = components.url else {
            throw URLError(.badURL)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: Self.callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL,
                      let comps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = comps.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: NSError(domain: "WebAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code in redirect"]))
                    return
                }

                // Exchange code for tokens
                Task {
                    do {
                        let token = try await self.exchangeGrokCodeForTokens(code: code, redirectURI: redirectURI)
                        continuation.resume(returning: token)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            session.start()
        }
    }

    private func exchangeGrokCodeForTokens(code: String, redirectURI: String) async throws -> String {
        guard let url = URL(string: Self.grokTokenEndpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let postParams = [
            "grant_type": "authorization_code",
            "client_id": Self.grokClientID,
            "code": code,
            "redirect_uri": redirectURI
        ]
        request.httpBody = postParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw NSError(domain: "WebAuth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse access token response"])
        }

        if let refreshToken = json["refresh_token"] as? String {
            _ = KeychainHelper.savePassword(service: "xai", account: "refresh_token", password: refreshToken)
        }

        _ = KeychainHelper.savePassword(service: "xai", account: "grok", password: accessToken)
        return accessToken
    }
}
