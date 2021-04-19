//
//  Reading.swift
//  Leastimator
//
//  Created by Hao Liu on 4/16/21.
//

import Foundation
import RealmSwift

// Legacy Realm car object.
class Reading : Object {
  @objc dynamic var id = 0
  @objc dynamic var value = 0
  @objc dynamic var date = Date()
  
  override static func primaryKey() -> String? {
    "id"
  }
}
