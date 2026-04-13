//
//  TeslaVehiclePicker.swift
//  Leastimator
//

import SwiftUI

struct TeslaVehiclePicker: View {
    let vehicles: [TeslaVehicle]
    let existingVehicleId: String?
    let onSelect: (TeslaVehicle) -> Void
    let onCancel: () -> Void
    
    @State private var showingMismatchAlert = false
    @State private var attemptedSelection: TeslaVehicle?
    
    var body: some View {
        NavigationStack {
            List(vehicles) { vehicle in
                Button {
                    handleSelection(vehicle)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(vehicle.safeDisplayName)
                                .font(.headline)
                            Text(vehicle.vin)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if existingVehicleId == vehicle.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Select Tesla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
            .alert("Binding Mismatch", isPresented: $showingMismatchAlert, presenting: attemptedSelection) { _ in
                Button("OK", role: .cancel) { }
            } message: { vehicle in
                Text("This local profile was previously bound to a different vehicle. Selecting '\(vehicle.safeDisplayName)' would cause a mismatch. Please select the correct vehicle.")
            }
        }
    }
    
    private func handleSelection(_ vehicle: TeslaVehicle) {
        if let existing = existingVehicleId, !existing.isEmpty, existing != vehicle.id {
            // Mismatch
            attemptedSelection = vehicle
            showingMismatchAlert = true
        } else {
            onSelect(vehicle)
        }
    }
}
