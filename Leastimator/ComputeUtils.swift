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
  let normalPredicatedMileage: Int
  
  let mileagePerDay: Double
  let mileagePerMonth: Int
  
  let allowedMileagePerDay: Int
  let usedDays: Int
  
  let mileageVariance: Int?
  let excessMileage: Int?
  let excessCharge: Int?
  
  let mileageShouldLessThan: Int
  let maxDriveToday: Int
  let leaseLeft: Int
  
  let isExpired: Bool
  
  let monthlyMileageDataForLineChart: [GraphPoint]
}


// Difference vs. monthly: it fills empty day with data from last day that has value.
// Not in use.
func prepareDailyDataForLineGraph(veh: Vehicle, readings: [OdoReading], usedDays: Int) -> [GraphPoint] {
  var data = [GraphPoint]()
  
  guard let startDate = veh.startDate else { return data }
  
  // Generate a date key to OdoReading map, in a certain day, the reading should be the largest one.
  let keyFormatter = DateFormatter()
  keyFormatter.dateFormat = "yyyy-MM-dd"
  let labelFormatter = DateFormatter()
  labelFormatter.dateFormat = "d"
  var readingMap: [String: Int64] = [:]
  
  // Add starting mileage.
  let startKey = keyFormatter.string(from: startDate)
  readingMap[startKey] = veh.starting
  
  for reading in readings {
    if let date = reading.date {
      let key = keyFormatter.string(from: date)
      readingMap[key] = reading.value
    }
  }
  
  // Iterate from starting date to current day.
  var maxReading = veh.starting
  for dayIndex in 0..<usedDays {
    var dayDiff = DateComponents()
    dayDiff.day = dayIndex
    let iterDate = Calendar.current.date(byAdding: dayDiff, to: startDate)
    if let iterDate = iterDate {
      let iterDateKey = keyFormatter.string(from: iterDate)
      var point = GraphPoint(value: Double(maxReading), label: labelFormatter.string(from: iterDate), significant: false)
      if let reading = readingMap[iterDateKey] {
        point.value = Double(reading)
        maxReading = max(maxReading, reading)
        point.significant = true
      }
      data.append(point)
    }
  }
  
  // It's possible that there is no reading entered in the current month but we want to add the max to it so that the graph can be drawn properly.
  data[data.count - 1].value = Double(maxReading)
  
  return data
}

// Convert vehicle info and reading history into a vector of LineGraph points for drawing.
func prepareMonthlyDataForLineGraph(veh: Vehicle, readings: [OdoReading], usedMonths: Int) -> [GraphPoint] {
  var data = [GraphPoint]()
  
  guard let startDate = veh.startDate else { return data }
  
  // Generate a date key to OdoReading map, in a certain month, the reading should be the largest one.
  let keyFormatter = DateFormatter()
  keyFormatter.dateFormat = "MMM yyyy"
  var readingMap: [String: Int64] = [:]
  
  // Add starting mileage.
  let startKey = keyFormatter.string(from: startDate)
  readingMap[startKey] = veh.starting
  
  for reading in readings {
    if let date = reading.date {
      let key = keyFormatter.string(from: date)
      readingMap[key] = reading.value
    }
  }
  
  // Iterate from starting date to current month.
  var maxReading = veh.starting
  for monthIndex in 0..<usedMonths {
    var monthDiff = DateComponents()
    monthDiff.month = monthIndex
    let iterDate = Calendar.current.date(byAdding: monthDiff, to: startDate)
    if let iterDate = iterDate {
      let iterDateKey = keyFormatter.string(from: iterDate)
      var point = GraphPoint(value: -1.0, label: keyFormatter.string(from: iterDate), significant: false)
      if let reading = readingMap[iterDateKey] {
        maxReading = max(maxReading, reading)
      }
      point.value = Double(maxReading)
      data.append(point)
    }
  }
  
  // It's possible that there is no reading entered in the current month but we want to add the max to it so that the graph can be drawn properly.
  data[data.count - 1].value = Double(maxReading)
  
  return data
}

func Compute(_ veh: Vehicle) -> ExtendedVehicleInfo {
  var readings: [OdoReading] = veh.readings?.map{ $0 } as! [OdoReading]
  readings.sort(by: { ($0.date ?? Date()).compare($1.date ?? Date()) == .orderedAscending })
  
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
    if veh.lengthOfLease == 0 {
      isExpired = false
    }
  }
  
  // Compute predicted mileage.
  var normalPredicatedMileage: Int = 0
  var mileagePerDay: Double = 0
  var mileagePerMonth: Int = 0
  // Can be zero.
  let usedMileage = Int(currentMileage - Int(veh.starting))
  
  let usedDays: Int
  let usedMonths: Int
  if let startDate = veh.startDate {
    usedDays = Calendar.current.dateComponents([.day],
                                               from: startDate,
                                               to: currentDate).day! + 1
    usedMonths = Calendar.current.dateComponents([.month],
                                                 from: startDate.startOfMonth(),
                                                 to: currentDate).month! + 1
  } else {
    // This should never happen because a start date is a must have.
    usedDays = 1
    usedMonths = 1
  }
  mileagePerDay = max(Double(usedMileage / usedDays), 0)
  mileagePerMonth = max(Int(usedMileage / usedMonths), 0)
  
  // Starting date + predicated mileage.
  normalPredicatedMileage = max(currentMileage, Int(Double(veh.starting) + Double(veh.lengthOfLease) / 12.0 * 365.0 * mileagePerDay))
  
  let mileageVariance = normalPredicatedMileage - Int(veh.allowed) - Int(veh.starting)
  let excessMileage = max(mileageVariance, 0)
  let excessCharge = Int(veh.fee * Float(excessMileage))
  
  let totalDays = max(1, (veh.lengthOfLease / 12 * 365))
  let allowedMileagePerDay: Int = Int(veh.allowed / totalDays)
  
  let mileageShouldLessThan = Int(veh.starting) + Int(allowedMileagePerDay * usedDays)
  let maxDriveToday = max(0, mileageShouldLessThan - currentMileage)
  let leaseLeft = max(0, Int(veh.lengthOfLease) - usedMonths)
  
  let monthlyData = prepareMonthlyDataForLineGraph(veh: veh, readings: readings, usedMonths: usedMonths)
  
  return ExtendedVehicleInfo(currentMileage: currentMileage,
                             leftMileage: leftMileage,
                             normalPredicatedMileage: normalPredicatedMileage,
                             mileagePerDay: mileagePerDay,
                             mileagePerMonth: mileagePerMonth,
                             allowedMileagePerDay: allowedMileagePerDay,
                             usedDays: usedDays,
                             mileageVariance: mileageVariance,
                             excessMileage: excessMileage,
                             excessCharge: excessCharge,
                             mileageShouldLessThan: mileageShouldLessThan,
                             maxDriveToday: maxDriveToday,
                             leaseLeft: leaseLeft,
                             isExpired: isExpired,
                             monthlyMileageDataForLineChart: monthlyData
  )
}
