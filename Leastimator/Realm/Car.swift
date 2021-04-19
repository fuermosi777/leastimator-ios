//
//  Realm.swift
//  Leastimator
//
//  Created by Hao Liu on 4/16/21.
//

import Foundation
import RealmSwift

// Legacy Realm car object.
class Car : Object {
  @objc dynamic var id = 0
  @objc dynamic var carIconName = ""
  @objc dynamic var nickname = ""
  @objc dynamic var startingMiles = 0
  @objc dynamic var milesAllowed = 0
  @objc dynamic var lengthOfLease = 0
  @objc dynamic var leaseStartDate = Date()
  @objc dynamic var fee = Float(0)
  var readings = List<Reading>()
  
  override static func primaryKey() -> String? {
    "id"
  }
}
