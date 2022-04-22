//
//  NormalWidget.swift
//  NormalWidget
//
//  Created by Hao Liu on 4/19/21.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData

struct Provider: IntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    let vehicle = Vehicle(context: PersistenceController.preview.container.viewContext)
    vehicle.name = "My drive"
    
    return SimpleEntry(date: Date(), configuration: ConfigurationIntent(), vehicle: vehicle)
  }
  
  func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let vehicle = Vehicle(context: PersistenceController.preview.container.viewContext)
    vehicle.name = "My drive"
    let entry = SimpleEntry(date: Date(), configuration: configuration, vehicle: vehicle)
    completion(entry)
  }
  
  func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SimpleEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    
    let managedObjectContext = PersistenceController.shared.container.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Vehicle")
    request.predicate = NSPredicate(format: "removed == nil OR removed == false")
    
    var results = [Vehicle]()
    do {
      results = try managedObjectContext.fetch(request) as! [Vehicle]
    } catch let error as NSError {
      print("Couldn't fetch \(error), \(error.userInfo)")
    }
    
    // Find the vehicle that should be shown. If a vehicle is set should show on widget then pick it, otherwise pick the first vehicle in the list if it's not empty.
    var vehicle: Vehicle?
    for veh in results {
      if veh.showOnWidget {
        vehicle = veh
        break
      }
    }
    if vehicle == nil && results.count > 0 {
      vehicle = results[0]
    }
    
    if vehicle != nil {
      let entry = SimpleEntry(date: currentDate, configuration: configuration, vehicle: vehicle!)
      entries.append(entry)
    }
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationIntent
  let vehicle: Vehicle
}

struct NormalWidgetEntryView : View {
  var entry: Provider.Entry
  var extendedInfo: ExtendedVehicleInfo {
    var readings = entry.vehicle.readings!.allObjects as! [OdoReading]
    readings.sort(by: { $0.date! < $1.date! })
    
    return Compute(entry.vehicle, readings)
  }
  var lengthUnit: LengthUnit {
    get {
      if let unit = LengthUnit(rawValue: entry.vehicle.lengthUnit) {
        return unit
      } else {
        return LengthUnit.mi
      }
    }
  }
  
  var body: some View {
    HStack(alignment: .center, spacing: nil){
      VStack(alignment: .leading) {
        if let normalPredicatedMileage = extendedInfo.normalPredicatedMileage {
          switch entry.configuration.primary {
          case .estimatedMileage, .unknown:
            ProgressCircle(progress: Float(Float(normalPredicatedMileage) / Float(entry.vehicle.allowed + entry.vehicle.starting))) {}
              .frame(width: 40.0, height: 40.0)
              .padding(.bottom, 20.0)
          case .currentMileage:
            ProgressCircle(progress: Float(Float(extendedInfo.currentMileage) / Float(entry.vehicle.allowed + entry.vehicle.starting))) {}
              .frame(width: 40.0, height: 40.0)
              .padding(.bottom, 20.0)
          }
          Text("\(entry.vehicle.name ?? "--")")
            .foregroundColor(.mainText)
            .fontWeight(.bold)
          HStack {
            switch entry.configuration.primary {
            case .estimatedMileage, .unknown:
              Text("\(normalPredicatedMileage)")
                .lineLimit(1)
                .foregroundColor(.mainText)
            case .currentMileage:
              Text("\(extendedInfo.currentMileage)")
                .lineLimit(1)
                .foregroundColor(.mainText)
            }
            Text(lengthUnit.shortFor)
              .font(.callout)
              .foregroundColor(.subText)
          }
        } else {
          ProgressCircle(progress: 0.0) {}
            .frame(width: 40.0, height: 40.0)
            .padding(.bottom, 20.0)
          Text("\(entry.vehicle.name ?? "--")")
            .foregroundColor(.mainText)
            .fontWeight(.bold)
          Text("Not enough data")
            .font(.callout)
            .foregroundColor(.subText)
        }
      }.padding(.horizontal, 15.0)
      
      Spacer()
    }
  }
  
  @main
  struct NormalWidget: Widget {
    let kind: String = "NormalWidget"
    
    var body: some WidgetConfiguration {
      IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
        NormalWidgetEntryView(entry: entry)
      }
      .configurationDisplayName("Quick Mileage Widget")
      .description("Select information shown in the widget.")
    }
  }
  
  struct NormalWidget_Previews: PreviewProvider {
    
    static var previews: some View {
      NormalWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), vehicle: Vehicle()))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
  }
}
