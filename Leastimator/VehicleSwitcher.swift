//
//  VehicleSwitcher.swift
//  Leastimator
//
//  Created by Antigravity on 4/28/26.
//

import SwiftUI

struct VehicleSwitcher: View {
    let vehicles: [Vehicle]
    let selectedVehicle: Vehicle?
    let onSelect: (Vehicle) -> Void
    let onSettings: () -> Void
    let onAddVehicle: () -> Void
    let statusColor: Color
    
    var body: some View {
        Menu {
            Section {
                ForEach(vehicles) { vehicle in
                    Button {
                        onSelect(vehicle)
                    } label: {
                        HStack {
                            Text(vehicle.name ?? "Unknown")
                            if vehicle == selectedVehicle {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Section {
                Button(action: onSettings) {
                    Label("Settings", systemImage: "gearshape.2")
                }
                Button(action: onAddVehicle) {
                    Label("Add Vehicle", systemImage: "plus")
                }
            }
        } label: {
            HStack(spacing: 8) {
                // Abbreviation Icon
                Text(selectedVehicle?.name?.vehicleAbbreviation ?? "??")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 22, height: 22)
                    .background(statusColor)
                    .clipShape(Circle())
                
                Text(selectedVehicle?.name ?? "Select Vehicle")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.mainText)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.subText)
            }
            .padding(.leading, 4)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.subBg.opacity(0.6)))
            .transition(.opacity)
        }
    }
}
