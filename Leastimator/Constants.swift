//
//  Constants.swift
//  Leastimator
//
//  Created by Antigravity on 4/16/26.
//

import Foundation

enum AppConstants {
    /// The cooldown period for Tesla vehicle synchronization in hours.
    static let teslaSyncCooldownHours: Int = 1
    
    /// The cooldown period for Tesla vehicle synchronization in seconds.
    static var teslaSyncCooldownSeconds: TimeInterval {
        #if DEBUG
        return 0
        #else
        return TimeInterval(teslaSyncCooldownHours * 3600)
        #endif
    }
}
