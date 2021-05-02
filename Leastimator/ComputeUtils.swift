//
//  ComputeUtils.swift
//  Leastimator
//
//  Created by Hao Liu on 4/24/21.
//

import SwiftUI
import CoreData

struct ExtendedVehicleInfo {
  let currentMileage: Int
  let leftMileage: Int
  
  // Predicated mileage based on all time driving.
  let normalPredicatedMileage: Int?
  
  let mileagePerDay: Int?
  let mileagePerMonth: Int?
  
  let excessMileage: Int?
  let excessCharge: Int?
  
  let mileageShouldLessThan: Int
  let maxDriveToday: Int
  let leaseLeft: Int
  
  let isExpired: Bool
  
  // Mileage snapshot for each month.
  let mileageSnapshots: [Double]
}

func Compute(_ veh: Vehicle, _ readings: [OdoReading]) -> ExtendedVehicleInfo {
  var currentMileage = Int(veh.starting)
  let currentDate = Date()
  
  if readings.count > 0 {
    if let lastReading = readings.last {
      currentMileage = Int(lastReading.value)
    }
  }
  
  let leftMileage = Int(max(Int(veh.allowed) + Int(veh.starting) - currentMileage, 0))
  
  var isExpired = false
  if let startDate = veh.startDate {
    let endDate = Calendar.current.date(byAdding: .month,
                                        value: Int(veh.lengthOfLease),
                                        to: startDate)
    if let endDate = endDate {
      isExpired = endDate < currentDate
    }
  }
  
  // Compute predicted mileage.
  var normalPredicatedMileage: Int? = nil
  var mileagePerDay: Int? = nil
  var mileagePerMonth: Int? = nil
  let usedMileage = Int(currentMileage - Int(veh.starting))
  
  let usedDays: Int
  let usedMonths: Int
  if let startDate = veh.startDate {
    usedDays = Calendar.current.dateComponents([.day],
                                               from: startDate,
                                               to: currentDate).day! + 1
    usedMonths = Calendar.current.dateComponents([.month],
                                                 from: startDate,
                                                 to: currentDate).month! + 1
  } else {
    // This should never happen because a start date is a must.
    usedDays = 1
    usedMonths = 1
  }
  mileagePerDay = Int(usedMileage / usedDays)
  mileagePerMonth = Int(usedMileage / usedMonths)
  
  // Starting date + predicated mileage.
  normalPredicatedMileage = max(currentMileage, Int(veh.starting) + Int(veh.lengthOfLease) / 12 * 365 * mileagePerDay!)
  
  var excessMileage: Int? = nil
  var excessCharge: Int? = nil
  if let predicatedMileage = normalPredicatedMileage {
    excessMileage = Int(max(predicatedMileage - Int(veh.allowed) - Int(veh.starting), 0))
    excessCharge = Int(veh.fee * Float(excessMileage!))
  }
  
  let totalDays = max(1, (veh.lengthOfLease / 12 * 365))
  let allowedMileagePerDay = Int(veh.allowed / totalDays)
  let mileageShouldLessThan = allowedMileagePerDay * usedDays
  let maxDriveToday = max(0, mileageShouldLessThan - currentMileage)
  let leaseLeft = max(0, Int(veh.lengthOfLease) - usedMonths)
  
  // Generate a key to OdoReading map.
  let keyFormatter = DateFormatter()
  keyFormatter.dateFormat = "MMM y"
  var readingMap: [String: OdoReading] = [:]
  for reading in readings {
    if let date = reading.date {
      let key = keyFormatter.string(from: date)
      readingMap[key] = reading
    }
  }
  
  var mileageSnapshots = [Double]()
  mileageSnapshots.append(Double(veh.starting))
  if let startDate = veh.startDate {
    var lastMileage = Double(veh.starting)
    
    for monthIndex in 0..<usedMonths {
      var monthDiff = DateComponents()
      monthDiff.month = monthIndex
      let iterDate = Calendar.current.date(byAdding: monthDiff, to: startDate)
      if let iterDate = iterDate {
        let iterDateKey = keyFormatter.string(from: iterDate)
        if let reading = readingMap[iterDateKey] {
          lastMileage = Double(reading.value)
        }
      }
      mileageSnapshots.append(lastMileage)
    }
  }

  return ExtendedVehicleInfo(currentMileage: currentMileage,
                             leftMileage: leftMileage,
                             normalPredicatedMileage: normalPredicatedMileage,
                             mileagePerDay: mileagePerDay,
                             mileagePerMonth: mileagePerMonth,
                             excessMileage: excessMileage,
                             excessCharge: excessCharge,
                             mileageShouldLessThan: mileageShouldLessThan,
                             maxDriveToday: maxDriveToday,
                             leaseLeft: leaseLeft,
                             isExpired: isExpired,
                             mileageSnapshots: mileageSnapshots)
}
