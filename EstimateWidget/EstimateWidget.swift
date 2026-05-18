//
//  EstimateWidget.swift
//  EstimateWidget
//
//  Created by Hao Liu on 7/4/23.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Provider

struct Provider: TimelineProvider {
  var moc: NSManagedObjectContext

  init(moc: NSManagedObjectContext) {
    self.moc = moc
  }

  /// Returns the vehicle to display: the one with `showOnWidget == true`,
  /// or the first active vehicle if none is flagged.
  func getVehicle() -> Vehicle? {
    let fetchRequest = Vehicle.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "removed == nil OR removed == false")

    do {
      let vehicles = try moc.fetch(fetchRequest)
      guard !vehicles.isEmpty else { return nil }
      if vehicles.count == 1 { return vehicles.first }
      let matched = vehicles.filter { $0.showOnWidget == true }
      return matched.first ?? vehicles.first
    } catch {
      print("EstimateWidget: failed to fetch vehicle – \(error)")
    }
    return nil
  }

  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), vehicle: getVehicle())
  }

  // BUG FIX: was getPlaceholderVehicle() which created a blank Vehicle
  // with nil name → showing "Unknown". Now uses the real vehicle.
  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(date: Date(), vehicle: getVehicle())
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [SimpleEntry] = []
    let currentDate = Date()
    for hourOffset in 0..<5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      entries.append(SimpleEntry(date: entryDate, vehicle: getVehicle()))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
  let date: Date
  let vehicle: Vehicle?
}

// MARK: - Widget Progress View

struct WidgetProgressView: View {
  let vehicle: Vehicle

  // MARK: Computed properties

  private var extendedInfo: ExtendedVehicleInfo {
    Compute(vehicle)
  }

  private var lengthUnit: LengthUnit {
    LengthUnit(rawValue: vehicle.lengthUnit) ?? .Imperial
  }

  /// Projected / limit  (clamped to [0, 1.15] for drawing)
  private var progress: Double {
    let limit = Double(vehicle.allowed + vehicle.starting)
    guard limit > 0 else { return 1.0 }
    return min(Double(extendedInfo.normalPredicatedMileage) / limit, 1.15)
  }

  private var statusColor: Color {
    Color.statusColor(progress: progress)
  }

  private var variance: Int {
    extendedInfo.mileageVariance ?? 0
  }

  // MARK: Layout constants
  private let ringSize: CGFloat = 60
  private let strokeWidth: CGFloat = 8
  private let arcFraction: Double = 0.75   // 270° sweep
  private let arcStartDegrees: Double = 135 // bottom-left → bottom-right

  // MARK: Body

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // ── Top: projected mileage ──────────────────────────────────
      VStack(alignment: .leading, spacing: 1) {
        Text("PROJECTED")
          .font(.rounded(9, weight: .bold))
          .foregroundColor(.subText)
          .tracking(1.5)

        HStack(alignment: .lastTextBaseline, spacing: 3) {
          Text("\(extendedInfo.normalPredicatedMileage)")
            .font(.rounded(28))
            .fontWeight(.bold)
            .monospacedDigit()
            .foregroundColor(.mainText)
            .minimumScaleFactor(0.6)
            .lineLimit(1)

          Text(lengthUnit.shortFor.uppercased())
            .font(.rounded(10, weight: .semibold))
            .foregroundColor(.subText)
        }

        Text("BY LEASE END")
          .font(.rounded(8, weight: .medium))
          .foregroundColor(.subText)
          .tracking(1)
      }

      Spacer(minLength: 40)

      // ── Bottom: vehicle name + variance ────────────────────────
      VStack(alignment: .leading, spacing: 4) {
        Text(vehicle.name ?? "Vehicle")
          .font(.rounded(12, weight: .semibold))
          .foregroundColor(.subText)
          .lineLimit(1)

        // Variance pill
        let sign = variance > 0 ? "+" : ""
        Text("\(sign)\(variance) \(lengthUnit.shortFor) vs limit")
          .font(.rounded(10))
          .fontWeight(.bold)
          .monospacedDigit()
          .foregroundColor(statusColor)
          .padding(.horizontal, 7)
          .padding(.vertical, 3)
          .background(statusColor.opacity(0.12))
          .cornerRadius(8)
      }
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 4)
    // ── Ring: background layer, top-right, sits behind projected text
    .background(alignment: .topTrailing) {
      ZStack {
        Circle()
          .trim(from: 0, to: CGFloat(arcFraction))
          .stroke(Color.mainText.opacity(0.08),
                  style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
          .rotationEffect(.degrees(arcStartDegrees))

        Circle()
          .trim(from: 0, to: CGFloat(min(progress, 1.0) * arcFraction))
          .stroke(statusColor,
                  style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
          .rotationEffect(.degrees(arcStartDegrees))
          .shadow(color: statusColor.opacity(0.35), radius: 4)
      }
      .frame(width: ringSize, height: ringSize)
      .offset(x: 8, y: 4)
    }
    .widgetBackground(Color(.systemBackground))
  }
}

// MARK: - Entry View

struct EstimateWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    if let vehicle = entry.vehicle {
      WidgetProgressView(vehicle: vehicle)
    } else {
      VStack(spacing: 6) {
        Image(systemName: "car.fill")
          .font(.system(size: 24))
          .foregroundColor(.subText)
        Text("Add a vehicle and enable it in Settings.")
          .font(.rounded(11))
          .foregroundColor(.subText)
          .multilineTextAlignment(.center)
      }
      .padding(14)
      .widgetBackground(Color(.systemBackground))
    }
  }
}

// MARK: - Widget Configuration

struct EstimateWidget: Widget {
  let kind: String = "EstimateWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: Provider(moc: PersistenceController.shared.container.viewContext)
    ) { entry in
      EstimateWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Estimate")
    .supportedFamilies([.systemSmall])
    .description("Display lease mileage estimation.")
  }
}
