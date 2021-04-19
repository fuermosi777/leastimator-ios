//
//  Realm.swift
//  Leastimator
//
//  Created by Hao Liu on 4/16/21.
//

import Foundation
import RealmSwift

enum RealmMigrator {
  static func setDefaultConfiguration() {
    let config = Realm.Configuration(schemaVersion: 1,)
  }
}
