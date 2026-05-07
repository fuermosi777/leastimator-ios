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
        VStack(spacing: 20) {
          Spacer()
          Image(systemName: "trash.circle")
            .font(.system(size: 64))
            .foregroundColor(.subText.opacity(0.3))
          
          Text("No Deleted Vehicles")
            .font(.inter(20, weight: .bold))
            .foregroundColor(.mainText)
          
          Text("Vehicles you delete will appear here and can be restored to your garage.")
            .font(.inter(15))
            .foregroundColor(.subText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
          Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      } else {
        ForEach(deletedVehicles) { vehicle in
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
              // Abbreviation Icon
              Text(vehicle.name?.vehicleAbbreviation ?? "??")
                .font(.jetBrainsMono(12))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 42, height: 42)
                .background(Color.subBg)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.mainText.opacity(0.1), lineWidth: 1))
              
              VStack(alignment: .leading, spacing: 2) {
                Text(vehicle.name ?? kUnknownVehicleName)
                  .font(.inter(15, weight: .bold))
                  .foregroundColor(.mainText)
                
                Text("\(vehicle.leaseSubtitle ?? "No lease info") · \(vehicle.allowed) \(vehicle.lengthUnit == LengthUnit.Metric.rawValue ? "km" : "mi")")
                  .font(.inter(12))
                  .foregroundColor(.subText)
              }
              
              Spacer()
              
              Button(action: { restore(vehicle) }) {
                HStack(spacing: 4) {
                  Image(systemName: "arrow.uturn.backward")
                  Text("Restore")
                }
                .font(.inter(12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(12)
              }
              .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color.subBg.opacity(0.3))
            .cornerRadius(18)
            .overlay(
              RoundedRectangle(cornerRadius: 18)
                .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
            )
          }
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .padding(.vertical, 4)
        }
      }
    }
    .scrollContentBackground(.hidden)
    .background(Color.mainBg)
    .navigationTitle("Deleted Vehicles")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func restore(_ vehicle: Vehicle) {
    vehicle.removed = false
    try? viewContext.save()
    WidgetCenter.shared.reloadAllTimelines()
  }
}
