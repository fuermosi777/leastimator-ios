//
//  RealmMigrator.swift
//  Leastimator
//
//  Created by Hao Liu on 4/16/21.
//

import Foundation
import RealmSwift

enum RealmMigrator {
  static private func migrationBlock(
    migration: Migration,
    oldSchemaVersion: UInt64
  ) {
    // Do nothing. It only support version 1.
  }
  
  static func setDefaultConfiguration() {
    let config = Realm.Configuration(schemaVersion: 1, migrationBlock: migrationBlock)
    Realm.Configuration.defaultConfiguration = config
  }
}
