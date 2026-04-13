//
//  TeslaAuthManager.swift
//  Leastimator
//

import Foundation
import AuthenticationServices

enum TeslaAuthError: LocalizedError {
    case invalidURL
    case authCanceled
    case missingCode
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .authCanceled: return "Authentication canceled"
        case .missingCode: return "Missing code in callback"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid response from token exchange"
        case .apiError(let msg): return "Tesla API Error: \(msg)"
        }
    }
}

struct TeslaTokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
}

class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

@MainActor
class TeslaAuthManager: NSObject {
    static let shared = TeslaAuthManager()
    
    let clientId = "628a0d75-570c-4fac-97b6-074090172ece"
    let clientSecret = "ta-secret.OM1KDtsXB@%OEgI&"
    let redirectUri = "https://liuhao.im/leastimator/callback"
    
    private var authSession: ASWebAuthenticationSession?
    private var presentationProvider = PresentationContextProvider()
    
    private override init() {}
    
    func authenticate() async throws -> TeslaTokens {
        let code = try await getAuthorizationCode()
        let tokenResponse = try await exchangeCodeForTokens(code: code)
        
        return TeslaTokens(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            expiresIn: tokenResponse.expires_in,
            createdAt: Date()
        )
    }
    
    // MARK: - Step 1: Browse to authenticate and get code
    private func getAuthorizationCode() async throws -> String {
        let state = UUID().uuidString
        var components = URLComponents(string: "https://auth.tesla.com/oauth2/v3/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "locale", value: "en-US"),
            URLQueryItem(name: "prompt", value: "login"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid vehicle_device_data offline_access"),
            URLQueryItem(name: "audience", value: "https://fleet-api.prd.na.vn.cloud.tesla.com"),
            URLQueryItem(name: "state", value: state)
        ]
        
        guard let url = components.url else {
            throw TeslaAuthError.invalidURL
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: "leastimator") { callbackURL, error in
                if let error = error {
                    if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                        continuation.resume(throwing: TeslaAuthError.authCanceled)
                    } else {
                        continuation.resume(throwing: TeslaAuthError.networkError(error))
                    }
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let queryItems = components.queryItems,
                      let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: TeslaAuthError.missingCode)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            authSession?.presentationContextProvider = presentationProvider
            authSession?.start()
        }
    }
    
    // MARK: - Step 2: Exchange code for Access Token
    private func exchangeCodeForTokens(code: String) async throws -> TeslaTokenResponse {
        guard let url = URL(string: "https://auth.tesla.com/oauth2/v3/token") else {
            throw TeslaAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "audience": "https://fleet-api.prd.na.vn.cloud.tesla.com",
            "redirect_uri": redirectUri
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw TeslaAuthError.apiError("Token exchange failed: \(body)")
        }
        
        return try JSONDecoder().decode(TeslaTokenResponse.self, from: data)
    }
    
    // MARK: - Step 3: Refresh Access Token
    func refreshTokens(refreshToken: String) async throws -> TeslaTokens {
        guard let url = URL(string: "https://auth.tesla.com/oauth2/v3/token") else {
            throw TeslaAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        // Note: Some API versions require client_secret here as well. Add if required.
        
        request.httpBody = components.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {
            throw TeslaAuthError.invalidResponse
        }
        
        let tokenResponse = try JSONDecoder().decode(TeslaTokenResponse.self, from: data)
        return TeslaTokens(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            expiresIn: tokenResponse.expires_in,
            createdAt: Date()
        )
    }
}
