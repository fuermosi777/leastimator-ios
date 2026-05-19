//
//  StatsSection.swift
//  Leastimator
//
//  Created by Antigravity on 5/5/26.
//

import SwiftUI

struct StatsSection: View {
    @ObservedObject var vehicle: Vehicle
    let extendedInfo: ExtendedVehicleInfo
    let lengthUnit: LengthUnit
    let isEditing: Bool
    
    @State private var currentOrder: [String] = []
    
    init(vehicle: Vehicle, extendedInfo: ExtendedVehicleInfo, lengthUnit: LengthUnit, isEditing: Bool) {
        self.vehicle = vehicle
        self.extendedInfo = extendedInfo
        self.lengthUnit = lengthUnit
        self.isEditing = isEditing
        _currentOrder = State(initialValue: vehicle.statsOrder)
    }
    
    private func move(index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < currentOrder.count else { return }
        var order = currentOrder
        order.swapAt(index, newIndex)
        currentOrder = order
        vehicle.statsOrder = order
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(currentOrder.enumerated()), id: \.element) { index, type in
                if index > 0 {
                    Divider()
                        .frame(height: 32)
                        .padding(.horizontal, 2)
                        .opacity(0.1)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if type == "DAILY AVG" {
                        StatCell(label: "DAILY AVG", value: String(format: "%.1f", extendedInfo.mileagePerDay), unit: lengthUnit.shortFor)
                    } else if type == "ODOMETER" {
                        StatCell(label: "ODOMETER", value: "\(extendedInfo.currentMileage)", unit: lengthUnit.shortFor)
                    } else {
                        StatCell(label: "LEASE LEFT", value: "\(extendedInfo.leaseLeft)", unit: "mo")
                    }
                    
                    if isEditing {
                        HStack(spacing: 12) {
                            if index > 0 {
                                Button(action: { move(index: index, direction: -1) }) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Spacer()
                            
                            if index < currentOrder.count - 1 {
                                Button(action: { move(index: index, direction: 1) }) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 8)
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 16)
        .padding(.trailing, 12)
        .background(Color.subBg.opacity(0.3))
        .cornerRadius(24) // Unified border radius
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isEditing ? Color.accentColor.opacity(0.5) : Color.mainText.opacity(0.05),
                        style: StrokeStyle(lineWidth: isEditing ? 2 : 1, dash: isEditing ? [4] : []))
        )
        .onAppear {
            currentOrder = vehicle.statsOrder
        }
        .onChange(of: vehicle) { newVehicle in
            currentOrder = newVehicle.statsOrder
        }
    }
}
