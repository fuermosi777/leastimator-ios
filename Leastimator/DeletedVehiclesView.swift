//
//  DeletedVehiclesView.swift
//  Leastimator
//

import SwiftUI
import WidgetKit

struct DeletedVehiclesView: View {
  @Environment(\.managedObjectContext) private var viewContext

  @FetchRequest(
    entity: Vehicle.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.name, ascending: true)],
    predicate: NSPredicate(format: "removed == true"))
  private var deletedVehicles: FetchedResults<Vehicle>

  var body: some View {
    List {
      if deletedVehicles.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "checkmark.circle")
            .font(.system(size: 44))
            .foregroundColor(.secondary)
          Text("No Deleted Vehicles")
            .font(.headline)
            .foregroundColor(.primary)
          Text("Vehicles you delete will appear here and can be restored.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      } else {
        ForEach(deletedVehicles) { vehicle in
          HStack(spacing: 12) {
            VehicleImage(data: vehicle.image, size: 44)

            VStack(alignment: .leading, spacing: 4) {
              Text(vehicle.name ?? kUnknownVehicleName)
                .font(.headline)

              if let startDate = vehicle.startDate {
                Text("Started \(startDate.formatted(date: .abbreviated, time: .omitted))")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }

            Spacer()

            Button("Restore") {
              restore(vehicle)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
          }
          .padding(.vertical, 4)
        }
      }
    }
    .navigationTitle("Deleted Vehicles")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func restore(_ vehicle: Vehicle) {
    vehicle.removed = false
    try? viewContext.save()
    WidgetCenter.shared.reloadAllTimelines()
  }
}
