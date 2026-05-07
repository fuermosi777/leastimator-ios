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
  
  let usedDays: Int

  let mileageVariance: Int?
  let excessMileage: Int?
  let excessCharge: Int?

  let allowedMileagePerDay: Double
  let mileageShouldLessThan: Int
  let maxDriveToday: Int
  let leaseLeft: Int
  let daysRemaining: Int

  let isExpired: Bool

}


// Difference vs. monthly: it fills empty day with data from last day that has value.
// Not in use.

enum HistoryTimeRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "ALL"
    
    var id: String { self.rawValue }
    
    var calendarComponent: Calendar.Component? {
        switch self {
        case .oneMonth: return .month
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .oneYear: return .year
        case .all: return nil
        }
    }
    
    var value: Int? {
        switch self {
        case .oneMonth: return 1
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 1
        case .all: return nil
        }
    }
}

struct HistoryPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct HistoryChartData {
    let actualPoints: [HistoryPoint]
    let targetPoints: [HistoryPoint]
    let totalDriven: Int
    let variancePercent: Int
    let isOverPace: Bool
    let rangeLabel: String
}

func prepareHistoryChartData(veh: Vehicle, readings: [OdoReading], range: HistoryTimeRange) -> HistoryChartData {
    let currentDate = Date()
    let calendar = Calendar.current
    
    var startDateForRange: Date
    if let component = range.calendarComponent, let value = range.value {
        startDateForRange = calendar.date(byAdding: component, value: -value, to: currentDate) ?? veh.startDate ?? currentDate
    } else {
        startDateForRange = veh.startDate ?? currentDate
    }
    
    // Ensure we don't go before the vehicle's start date
    if let vehStart = veh.startDate, startDateForRange < vehStart {
        startDateForRange = vehStart
    }
    
    // Filter readings for the range
    let filteredReadings = readings.filter { ($0.date ?? Date()) >= startDateForRange }
    
    // 1. Actual Points
    var actualPoints: [HistoryPoint] = []
    
    // Add a point for the start of the range if there's a reading before it
    if let firstInRange = filteredReadings.first, let firstDate = firstInRange.date, firstDate > startDateForRange {
        // Find the last reading BEFORE the range start
        let beforeRange = readings.filter { ($0.date ?? Date()) < startDateForRange }.last
        let startValue = Double(beforeRange?.value ?? veh.starting)
        actualPoints.append(HistoryPoint(date: startDateForRange, value: startValue))
    } else if filteredReadings.isEmpty {
        // No readings in range, use current mileage or starting
        let lastReading = readings.last
        let val = Double(lastReading?.value ?? veh.starting)
        actualPoints.append(HistoryPoint(date: startDateForRange, value: val))
    }
    
    for rd in filteredReadings {
        actualPoints.append(HistoryPoint(date: rd.date ?? Date(), value: Double(rd.value)))
    }
    
    // Add current date point to extend the line
    if let last = actualPoints.last, last.date < currentDate {
        actualPoints.append(HistoryPoint(date: currentDate, value: last.value))
    }
    
    // 2. Target Points
    var targetPoints: [HistoryPoint] = []
    let totalLeaseDays = max(1.0, Double(veh.lengthOfLease) / 12.0 * 365.25)
    let allowedPerDay = Double(veh.allowed) / totalLeaseDays
    
    func targetValue(at date: Date) -> Double {
        guard let vehStart = veh.startDate else { return Double(veh.starting) }
        let daysSinceStart = Double(calendar.dateComponents([.day], from: vehStart, to: date).day ?? 0)
        return Double(veh.starting) + (allowedPerDay * daysSinceStart)
    }
    
    targetPoints.append(HistoryPoint(date: startDateForRange, value: targetValue(at: startDateForRange)))
    targetPoints.append(HistoryPoint(date: currentDate, value: targetValue(at: currentDate)))
    
    // 3. Stats
    let startMileage = actualPoints.first?.value ?? Double(veh.starting)
    let endMileage = actualPoints.last?.value ?? startMileage
    let totalDriven = Int(endMileage - startMileage)
    
    let targetEnd = targetPoints.last?.value ?? endMileage
    let isOverPace = endMileage > targetEnd
    let variance = abs(endMileage - targetEnd)
    let variancePercent = targetEnd > 0 ? Int((variance / targetEnd) * 100) : 0
    
    // Range Label
    let rangeLabel: String
    if range == .all {
        let months = calendar.dateComponents([.month], from: veh.startDate ?? currentDate, to: currentDate).month ?? 0
        rangeLabel = "\(months + 1) MO"
    } else {
        rangeLabel = range.rawValue
    }
    
    return HistoryChartData(
        actualPoints: actualPoints,
        targetPoints: targetPoints,
        totalDriven: totalDriven,
        variancePercent: variancePercent,
        isOverPace: isOverPace,
        rangeLabel: rangeLabel
    )
}

func Compute(_ veh: Vehicle) -> ExtendedVehicleInfo {
  var readings: [OdoReading] = (veh.readings?.map{ $0 } as? [OdoReading] ?? []).filter { !$0.isDeleted }
  readings.sort(by: { ($0.date ?? Date()).compare($1.date ?? Date()) == .orderedAscending })
  
  let startingMileage = Int(veh.starting)
  let allowedMileage = Int(veh.allowed)
  
  var currentMileage = startingMileage
  let currentDate = Date()
  
  if readings.count > 0 {
    if let lastReading = readings.last {
      currentMileage = Int(lastReading.value)
    }
  }
  
  let leftMileage = max(allowedMileage + startingMileage - currentMileage, 0)
  
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
  let usedMileage = currentMileage - startingMileage
  
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
  
  let mileagePerDay = max(Double(usedMileage) / Double(usedDays), 0.0)
  let mileagePerMonth = max(Double(usedMileage) / Double(usedMonths), 0.0)
  
  let totalDays = Double(veh.lengthOfLease) / 12.0 * 365.25
  let daysRemaining = max(0.0, totalDays - Double(usedDays))
  
  // Starting date + predicated mileage.
  let normalPredicatedMileage = max(currentMileage, currentMileage + Int((daysRemaining * mileagePerDay).rounded()))
  
  let mileageVariance = normalPredicatedMileage - allowedMileage - startingMileage
  let excessMileage = max(mileageVariance, 0)
  let excessCharge = Int((Double(veh.fee) * Double(excessMileage)).rounded())
  
  let allowedMileagePerDay: Double = Double(allowedMileage) / max(1.0, totalDays)
  let mileageShouldLessThan = startingMileage + Int((allowedMileagePerDay * Double(usedDays)).rounded())
  let maxDriveToday = max(0, mileageShouldLessThan - currentMileage)
  let leaseLeft = max(0, Int(veh.lengthOfLease) - (usedMonths - 1))
  
  return ExtendedVehicleInfo(currentMileage: currentMileage,
                             leftMileage: leftMileage,
                             normalPredicatedMileage: normalPredicatedMileage,
                             mileagePerDay: mileagePerDay,
                             mileagePerMonth: Int(mileagePerMonth.rounded()),
                             usedDays: usedDays,
                             mileageVariance: mileageVariance,
                             excessMileage: excessMileage,
                             excessCharge: excessCharge,
                             allowedMileagePerDay: allowedMileagePerDay,
                             mileageShouldLessThan: mileageShouldLessThan,
                             maxDriveToday: maxDriveToday,
                             leaseLeft: leaseLeft,
                             daysRemaining: Int(daysRemaining.rounded()),
                             isExpired: isExpired
  )
}
