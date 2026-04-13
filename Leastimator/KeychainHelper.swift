//
//  KeychainHelper.swift
//  Leastimator
//

import Foundation
import Security

struct TeslaTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int // in seconds
    let createdAt: Date // our local record of when we got this token
    
    var isExpired: Bool {
        // Subtract a 5-minute buffer
        let expiryDate = createdAt.addingTimeInterval(TimeInterval(expiresIn - 300))
        return Date() >= expiryDate
    }
}

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service = "com.leastimator.tesla.tokens"
    
    private init() {}
    
    func save(_ tokens: TeslaTokens, for connectionId: String) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        
        let query = [
            kSecClass: kSecClassGenericPassword as String,
            kSecAttrAccount: connectionId,
            kSecAttrService: service,
        ] as [String: Any]
        
        let attributesToUpdate = [kSecValueData: data] as [String: Any]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        if status == errSecItemNotFound {
            let newItem = [
                kSecClass: kSecClassGenericPassword as String,
                kSecAttrAccount: connectionId,
                kSecAttrService: service,
                kSecValueData: data
            ] as [String: Any]
            
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
    
    func load(for connectionId: String) -> TeslaTokens? {
        let query = [
            kSecClass: kSecClassGenericPassword as String,
            kSecAttrAccount: connectionId,
            kSecAttrService: service,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return try? JSONDecoder().decode(TeslaTokens.self, from: data)
        }
        return nil
    }
    
    func delete(for connectionId: String) {
        let query = [
            kSecClass: kSecClassGenericPassword as String,
            kSecAttrAccount: connectionId,
            kSecAttrService: service
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
}
