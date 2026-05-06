//
//  StatsSection.swift
//  Leastimator
//
//  Created by Antigravity on 5/5/26.
//

import SwiftUI

struct StatsSection: View {
    let extendedInfo: ExtendedVehicleInfo
    let lengthUnit: LengthUnit
    
    var body: some View {
        HStack(spacing: 0) {
            StatCell(label: "DAILY AVG", value: String(format: "%.1f", extendedInfo.mileagePerDay), unit: lengthUnit.shortFor)
            
            Divider()
                .frame(height: 32)
                .padding(.horizontal, 2)
                .opacity(0.1)
            
            StatCell(label: "ODOMETER", value: "\(extendedInfo.currentMileage)", unit: lengthUnit.shortFor)
            
            Divider()
                .frame(height: 32)
                .padding(.horizontal, 2)
                .opacity(0.1)
            
            StatCell(label: "LEASE LEFT", value: "\(extendedInfo.leaseLeft)", unit: "mo")
        }
        .padding(.vertical, 16)
        .padding(.trailing, 12)
        .background(Color.subBg.opacity(0.3))
        .cornerRadius(24) // Unified border radius
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
        )
    }
}
