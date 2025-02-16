//  Copyright © 2025 Compiler, Inc. All rights reserved.

import AuthenticationServices
import SwiftUI

public protocol KeychainManaging: Actor {
    func save(_ data: String, service: String, account: String) async
    func read(service: String, account: String) async -> String?
}

// Helper for Keychain operations
public actor KeychainHelper: KeychainManaging {
    public static let standard = KeychainHelper()
    public init() {}
    
    public func save(_ data: String, service: String, account: String) async {
        guard let data = data.data(using: .utf8) else { return }
        
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        // First remove any existing item
        SecItemDelete(query)
        
        // Add the new item
        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            print("Error saving to Keychain: \(status)")
            return
        }
    }
    
    public func read(service: String, account: String) async -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
}
