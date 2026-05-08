//
//  ICloudManager.swift
//  Leastimator
//
//  Created by Antigravity on 5/7/26.
//

import Foundation
import CloudKit

class ICloudManager {
    static let shared = ICloudManager()
    
    private init() {}
    
    /// Checks if the user is currently logged into an iCloud account.
    func checkICloudStatus() async -> Bool {
        do {
            let status = try await CKContainer.default().accountStatus()
            return status == .available
        } catch {
            return false
        }
    }
}
