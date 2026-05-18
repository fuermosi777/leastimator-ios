//
//  ProjectedMileageExplanationView.swift
//  Leastimator
//
//  Created by Antigravity on 5/5/26.
//

import SwiftUI

struct ProjectedMileageExplanationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vehicle: Vehicle
    
    var info: ExtendedVehicleInfo {
        Compute(vehicle)
    }
    
    var lengthUnit: String {
        LengthUnit(rawValue: vehicle.lengthUnit)?.shortFor ?? "mi"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    formulaSection
                    
                    calculationBreakdown
                    
                    tipSection
                    
                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            .background(Color.mainBg.ignoresSafeArea())
            .navigationTitle("How it's Calculated")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projected Mileage")
                .font(.rounded(24, weight: .bold))
                .foregroundColor(.mainText)
            
            Text("We use your actual driving history to predict where you'll end up at the end of your lease.")
                .font(.rounded(16))
                .foregroundColor(.subText)
                .lineSpacing(4)
        }
    }
    
    private var formulaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THE FORMULA")
                .font(.rounded(12, weight: .bold))
                .foregroundColor(.accentColor)
                .tracking(1.2)
            
            VStack(alignment: .center, spacing: 8) {
                Text("Current + (Avg. Daily × Days Left)")
                    .font(.rounded(18, weight: .bold))
                    .foregroundColor(.mainText)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.subBg.opacity(0.5))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    private var calculationBreakdown: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("YOUR DATA")
                .font(.rounded(12, weight: .bold))
                .foregroundColor(.accentColor)
                .tracking(1.2)
            
            VStack(spacing: 1) {
                dataRow(label: "Current Odometer", value: "\(info.currentMileage) \(lengthUnit)")
                dataRow(label: "Daily Average", value: String(format: "%.1f %@ / day", info.mileagePerDay, lengthUnit), isHighlighted: true)
                dataRow(label: "Days Remaining", value: "\(info.daysRemaining) days")
            }
            .background(Color.subBg.opacity(0.3))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    private func dataRow(label: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.rounded(15))
                .foregroundColor(.subText)
            Spacer()
            Text(value)
                .font(.rounded(15, weight: isHighlighted ? .bold : .medium))
                .foregroundColor(isHighlighted ? .accentColor : .mainText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var tipSection: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("More data = Better accuracy")
                    .font(.rounded(15, weight: .bold))
                    .foregroundColor(.mainText)
                
                Text("The more odometer readings you add over time, the more accurately we can account for seasonal driving changes and long trips.")
                    .font(.rounded(14))
                    .foregroundColor(.subText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(20)
    }
}
