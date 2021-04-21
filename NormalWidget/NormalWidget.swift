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
    SimpleEntry(date: Date(), configuration: ConfigurationIntent(), carCount: 1)
  }
  
  func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let entry = SimpleEntry(date: Date(), configuration: configuration, carCount: 1)
    completion(entry)
  }
  
  func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SimpleEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    
    let managedObjectContext = PersistenceController.shared.container.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Vehicle")
    request.predicate = NSPredicate(format: "removed == nil OR removed == false")
    
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      var results = [Vehicle]()
      do {
        results = try managedObjectContext.fetch(request) as! [Vehicle]
        print("+++", results.count)
      } catch let error as NSError {
        print("Couldn't fetch \(error), \(error.userInfo)")
      }
      
      let entry = SimpleEntry(date: entryDate, configuration: configuration, carCount: results.count)
      entries.append(entry)
    }
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationIntent
  let carCount: Int
}

struct NormalWidgetEntryView : View {
  var entry: Provider.Entry
  
  var body: some View {
    VStack {
      Text(entry.date, style: .time)
      Text("\(entry.carCount)")
    }
  }
}

@main
struct NormalWidget: Widget {
  let kind: String = "NormalWidget"
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      NormalWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("My Widget")
    .description("This is an example widget.")
  }
}

struct NormalWidget_Previews: PreviewProvider {
  static var previews: some View {
    NormalWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), carCount: 1))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
