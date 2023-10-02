//
//  EstimateWidget.swift
//  EstimateWidget
//
//  Created by Hao Liu on 7/4/23.
//

import WidgetKit
import SwiftUI
import CoreData

let kUnknownVehicleName = "Unknown"

struct Provider: TimelineProvider {
  var moc: NSManagedObjectContext
  
  init(moc: NSManagedObjectContext) {
    self.moc = moc
  }
  
  func getVehicle() -> Vehicle? {
    let fetchRequest = Vehicle.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "removed == nil OR removed == false")
    
    do {
      let vehicles = try moc.fetch(fetchRequest)
      if vehicles.isEmpty {
        return nil
      }
      if vehicles.count == 1 {
        return vehicles.first!
      }
      if vehicles.count > 1 {
        let matched = vehicles.filter { $0.showOnWidget == true}
        if matched.isEmpty {
          return vehicles.first
        } else {
          return matched.first!
        }
      }
    } catch {
      // This should not happen.
      print("Error: failed to fetch vehicle in widget.")
    }
    
    return nil
  }
  
  func getPlaceholderVehicle() -> Vehicle {
    let phVehicle = Vehicle(context: moc)
    
    return phVehicle
  }
  
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), vehicle: getPlaceholderVehicle())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let entry = SimpleEntry(date: Date(), vehicle: getPlaceholderVehicle())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SimpleEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, vehicle: getVehicle())
      entries.append(entry)
    }
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let vehicle: Vehicle?
}

struct EstimateProgressView : View {
  var vehicle: Vehicle
  
  // TODO: extract logic to util.
  var extendedInfo: ExtendedVehicleInfo {
    Compute(vehicle)
  }
  
  // TODO: extract logic to util.
  var progressPercentage: Float {
    let up = Float(extendedInfo.normalPredicatedMileage)
    let down = Float(vehicle.allowed + vehicle.starting)
    if down > 0 {
      return min(Float(up / down), 1.0)
    }
    return 1.0
  }
  
  // TODO: extract logic to util.
  var lengthUnit: LengthUnit {
    get {
      if let unit = LengthUnit(rawValue: vehicle.lengthUnit) {
        return unit
      } else {
        return .Imperial
      }
    }
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Text(vehicle.name ?? kUnknownVehicleName)
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundColor(.mainText)
          .lineLimit(1)
        
        Spacer()
        
        if let image = vehicle.image {
          VehicleImage(data: image, size: 44.0)
        }
      }
      
      Spacer()
      
      HStack(alignment: .lastTextBaseline) {
        Text("\(extendedInfo.normalPredicatedMileage)")
          .lineLimit(1)
          .font(.system(size: 20, weight: .bold, design: .rounded))
          .foregroundColor(.mainText)
        Text(lengthUnit.longName)
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundColor(.subText)
      }
      
      ProgressBar(progress: progressPercentage,
                  colorOverride: vehicle.allowed > 0 ? nil : Color.accentColor,
                  length: 120.0)
    }
  }
}

struct EstimateWidgetEntryView : View {
  var entry: Provider.Entry
  
  var body: some View {
    VStack {
      if let vehicle = entry.vehicle {
        EstimateProgressView(vehicle: vehicle)
      } else {
        Text("Please add an vehicle and set it showing up in widget.")
          .font(.subheadline)
          .foregroundColor(.subText)
      }
    }.padding(20.0)
  }
}

struct EstimateWidget: Widget {
  let kind: String = "EstimateWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind,
                        provider: Provider(moc: PersistenceController.shared.container.viewContext)) { entry in
      EstimateWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Estimate")
    .supportedFamilies([.systemSmall])
    .description("Display lease estimation.")
  }
}
