//
//  EstimateWidget.swift
//  EstimateWidget
//
//  Created by Hao Liu on 7/4/23.
//

import WidgetKit
import SwiftUI
import CoreData
import AppIntents

// MARK: - Snapshot

/// Everything the widget draws, flattened into a value type.
///
/// The timeline used to carry the `Vehicle` managed object itself, which is unsafe:
/// managed objects are bound to their context and can fault or go stale once CloudKit
/// merges changes underneath a timeline that WidgetKit is still holding.
struct VehicleSnapshot: Equatable {
  let name: String
  let projectedMileage: Int
  let currentMileage: Int
  let allowedMileage: Int
  let mileagePerDay: Double
  let variance: Int
  /// Projected / limit, clamped to [0, 1.15] for drawing.
  let progress: Double
  let lengthUnit: LengthUnit

  init(name: String, projectedMileage: Int, currentMileage: Int, allowedMileage: Int,
       mileagePerDay: Double, variance: Int, progress: Double, lengthUnit: LengthUnit) {
    self.name = name
    self.projectedMileage = projectedMileage
    self.currentMileage = currentMileage
    self.allowedMileage = allowedMileage
    self.mileagePerDay = mileagePerDay
    self.variance = variance
    self.progress = progress
    self.lengthUnit = lengthUnit
  }

  init(vehicle: Vehicle) {
    let info = Compute(vehicle)
    self.name = vehicle.name ?? "Vehicle"
    self.projectedMileage = info.normalPredicatedMileage
    self.currentMileage = info.currentMileage
    self.allowedMileage = Int(vehicle.allowed)
    self.mileagePerDay = info.mileagePerDay
    self.variance = info.mileageVariance ?? 0
    self.lengthUnit = LengthUnit(rawValue: vehicle.lengthUnit) ?? .Imperial

    let limit = Double(vehicle.allowed + vehicle.starting)
    self.progress = limit > 0 ? min(Double(info.normalPredicatedMileage) / limit, 1.15) : 1.0
  }

  /// e.g. "+320 mi vs limit" / "-150 mi vs limit"
  var varianceLabel: String {
    let sign = variance > 0 ? "+" : ""
    return "\(sign)\(variance) \(lengthUnit.shortFor) vs limit"
  }
}

// MARK: - Provider

@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
  var moc: NSManagedObjectContext

  init(moc: NSManagedObjectContext) {
    self.moc = moc
  }

  /// Resolves the configured vehicle, falling back to the legacy `showOnWidget` flag.
  ///
  /// Widgets added before configuration existed have no intent selection, so without
  /// this fallback they would all go blank on update.
  private func vehicle(for configuration: SelectVehicleIntent) -> Vehicle? {
    if let id = configuration.vehicle?.id,
       let vehicle = VehicleEntity.resolveVehicle(id: id, in: moc) {
      return vehicle
    }
    return VehicleEntity.widgetDefault(in: moc)
  }

  private func snapshot(for configuration: SelectVehicleIntent) -> VehicleSnapshot? {
    vehicle(for: configuration).map(VehicleSnapshot.init)
  }

  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), snapshot: snapshot(for: SelectVehicleIntent()))
  }

  func snapshot(for configuration: SelectVehicleIntent, in context: Context) async -> SimpleEntry {
    SimpleEntry(date: Date(), snapshot: snapshot(for: configuration))
  }

  func timeline(for configuration: SelectVehicleIntent, in context: Context) async -> Timeline<SimpleEntry> {
    // Computed once and shared across entries: the projection only changes when a new
    // reading arrives, which reloads the timeline anyway.
    let snapshot = snapshot(for: configuration)
    let currentDate = Date()

    let entries = (0..<5).compactMap { hourOffset -> SimpleEntry? in
      guard let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) else {
        return nil
      }
      return SimpleEntry(date: entryDate, snapshot: snapshot)
    }

    return Timeline(entries: entries, policy: .atEnd)
  }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
  let date: Date
  let snapshot: VehicleSnapshot?
}

// MARK: - Configuration Intent

@available(iOS 17.0, *)
struct SelectVehicleIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Select Vehicle"
  static var description = IntentDescription("Choose which vehicle this widget shows.")

  @Parameter(title: "Vehicle")
  var vehicle: VehicleEntity?

  init() {}

  init(vehicle: VehicleEntity?) {
    self.vehicle = vehicle
  }
}

// MARK: - Widget Progress View

struct WidgetProgressView: View {
  let snapshot: VehicleSnapshot

  // MARK: Computed properties

  private var lengthUnit: LengthUnit { snapshot.lengthUnit }

  private var progress: Double { snapshot.progress }

  private var statusColor: Color {
    Color.statusColor(progress: progress)
  }

  private var variance: Int { snapshot.variance }

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
          Text("\(snapshot.projectedMileage)")
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
        Text(snapshot.name)
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

// MARK: - Medium

/// Three columns spanning the full width: ring, then the projected/lease-end/name
/// block, then a vertical stack of the three secondary metrics.
@available(iOS 17.0, *)
struct WidgetMediumView: View {
  let snapshot: VehicleSnapshot

  private var statusColor: Color { Color.statusColor(progress: snapshot.progress) }

  private let ringSize: CGFloat = 64
  private let strokeWidth: CGFloat = 8
  private let arcFraction: Double = 0.75   // 270° sweep
  private let arcStartDegrees: Double = 135 // bottom-left → bottom-right

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      // ── Left: ring ───────────────────────────────────────────────
      ZStack {
        Circle()
          .trim(from: 0, to: CGFloat(arcFraction))
          .stroke(Color.mainText.opacity(0.08),
                  style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
          .rotationEffect(.degrees(arcStartDegrees))

        Circle()
          .trim(from: 0, to: CGFloat(min(snapshot.progress, 1.0) * arcFraction))
          .stroke(statusColor,
                  style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
          .rotationEffect(.degrees(arcStartDegrees))
          .shadow(color: statusColor.opacity(0.35), radius: 4)
      }
      .frame(width: ringSize, height: ringSize)

      // ── Middle: projected mileage, lease end, name + variance ────
      VStack(alignment: .leading, spacing: 1) {
        Text("PROJECTED")
          .font(.rounded(9, weight: .bold))
          .foregroundColor(.subText)
          .tracking(1.5)

        HStack(alignment: .lastTextBaseline, spacing: 3) {
          Text("\(snapshot.projectedMileage)")
            .font(.rounded(26))
            .fontWeight(.bold)
            .monospacedDigit()
            .foregroundColor(.mainText)
            .lineLimit(1)
            .minimumScaleFactor(0.6)

          Text(snapshot.lengthUnit.shortFor.uppercased())
            .font(.rounded(10, weight: .semibold))
            .foregroundColor(.subText)
        }

        Text("BY LEASE END")
          .font(.rounded(8, weight: .medium))
          .foregroundColor(.subText)
          .tracking(1)

        Spacer(minLength: 8)

        Text(snapshot.name)
          .font(.rounded(12, weight: .semibold))
          .foregroundColor(.subText)
          .lineLimit(1)

        Text(snapshot.varianceLabel)
          .font(.rounded(10))
          .fontWeight(.bold)
          .monospacedDigit()
          .foregroundColor(statusColor)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

      // ── Right: vertical metrics ───────────────────────────────────
      VStack(alignment: .leading, spacing: 10) {
        metric(label: "ALLOWED",
               value: "\(snapshot.allowedMileage)",
               color: .mainText)
        metric(label: "CURRENT",
               value: "\(snapshot.currentMileage)",
               color: .mainText)
        metric(label: "DAILY AVG",
               value: String(format: "%.1f", snapshot.mileagePerDay),
               color: statusColor)
      }
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 6)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .widgetBackground(Color(.systemBackground))
  }

  private func metric(label: String, value: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(label)
        .font(.rounded(8, weight: .bold))
        .foregroundColor(.subText)
        .tracking(0.5)
        .lineLimit(1)
        .fixedSize()
      HStack(alignment: .lastTextBaseline, spacing: 3) {
        Text(value)
          .font(.rounded(16, weight: .bold))
          .monospacedDigit()
          .foregroundColor(color)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        Text(snapshot.lengthUnit.shortFor)
          .font(.rounded(9, weight: .semibold))
          .foregroundColor(.subText)
      }
    }
  }
}

#Preview("Medium", as: .systemMedium) {
  EstimateWidget()
} timeline: {
  SimpleEntry(date: .now, snapshot: VehicleSnapshot(
    name: "Model 4",
    projectedMileage: 12338,
    currentMileage: 12338,
    allowedMileage: 33000,
    mileagePerDay: 8.7,
    variance: -20688,
    progress: 0.37,
    lengthUnit: .Imperial
  ))
}

// MARK: - Lock screen accessories

/// Lock screen widgets are rendered as a monochrome stencil, so these deliberately
/// avoid the status palette — colour would simply be flattened away.
@available(iOS 17.0, *)
struct WidgetAccessoryRectangularView: View {
  let snapshot: VehicleSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(snapshot.name)
        .font(.headline)
        .lineLimit(1)

      HStack(alignment: .lastTextBaseline, spacing: 3) {
        Text("\(snapshot.projectedMileage)")
          .font(.title3)
          .fontWeight(.semibold)
          .monospacedDigit()
        Text(snapshot.lengthUnit.shortFor)
          .font(.caption2)
      }

      Text(snapshot.varianceLabel)
        .font(.caption2)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

@available(iOS 17.0, *)
struct WidgetAccessoryCircularView: View {
  let snapshot: VehicleSnapshot

  var body: some View {
    Gauge(value: min(snapshot.progress, 1.0)) {
      Image(systemName: "car.fill")
    } currentValueLabel: {
      Text("\(Int((min(snapshot.progress, 1.0) * 100).rounded()))")
        .monospacedDigit()
    }
    .gaugeStyle(.accessoryCircularCapacity)
  }
}

// MARK: - Entry View

@available(iOS 17.0, *)
struct EstimateWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  var entry: Provider.Entry

  var body: some View {
    if let snapshot = entry.snapshot {
      switch family {
        case .accessoryRectangular:
          WidgetAccessoryRectangularView(snapshot: snapshot)
        case .accessoryCircular:
          WidgetAccessoryCircularView(snapshot: snapshot)
        case .systemMedium:
          WidgetMediumView(snapshot: snapshot)
        default:
          WidgetProgressView(snapshot: snapshot)
      }
    } else {
      placeholder
    }
  }

  @ViewBuilder
  private var placeholder: some View {
    switch family {
      case .accessoryRectangular:
        Text("No vehicle")
          .font(.headline)
      case .accessoryCircular:
        Image(systemName: "car.fill")
      default:
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

@available(iOS 17.0, *)
struct EstimateWidget: Widget {
  // Unchanged so widgets already on a home screen keep their identity across the
  // switch from StaticConfiguration.
  let kind: String = "EstimateWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectVehicleIntent.self,
      provider: Provider(moc: PersistenceController.shared.container.viewContext)
    ) { entry in
      EstimateWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Estimate")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    .description("Display lease mileage estimation. Add one widget per vehicle.")
  }
}
