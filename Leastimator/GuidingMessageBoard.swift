//
//  GuidingMessageBoard.swift
//  Leastimator
//
//  Created by Antigravity on 5/5/26.
//

import SwiftUI

struct GuidingMessageBoard: View {
    @ObservedObject var vehicle: Vehicle
    let extendedInfo: ExtendedVehicleInfo
    let lengthUnit: LengthUnit
    
    @State private var selection: Int
    @State private var currentlyPinned: Int
    
    init(vehicle: Vehicle, extendedInfo: ExtendedVehicleInfo, lengthUnit: LengthUnit) {
        self.vehicle = vehicle
        self.extendedInfo = extendedInfo
        self.lengthUnit = lengthUnit
        let pinned = vehicle.pinnedMessageIndex
        _selection = State(initialValue: pinned)
        _currentlyPinned = State(initialValue: pinned)
    }
    
    static let messageCount = 3

    var sortedIndices: [Int] {
        let pinned = currentlyPinned
        let others = Array(0..<Self.messageCount).filter { $0 != pinned }
        return [pinned] + others
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Card Container
            ZStack(alignment: .top) {
                // Card background and border
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.subBg.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
                    )
                    .frame(height: 96)
                
                // TabView extending slightly lower to push dots closer to the bottom card border
                TabView(selection: $selection) {
                    ForEach(sortedIndices, id: \.self) { index in
                        messageView(for: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(height: 104) // Taller frame to place dots near/on the bottom border line
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.label.withAlphaComponent(0.25)
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.08)
                }
            }
            
            // Pin Button
            Button(action: {
                let newPinned = currentlyPinned == selection ? 0 : selection
                vehicle.pinnedMessageIndex = newPinned
                currentlyPinned = newPinned
            }) {
                Image(systemName: currentlyPinned == selection ? "pin.fill" : "pin")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(currentlyPinned == selection ? .accentColor : .subText)
                    .padding(12)
                    .background(Color.mainBg.opacity(0.001))
            }
            .padding(4)
            .buttonStyle(.plain)
        }
        .frame(height: 96, alignment: .top)
    }
    
    @ViewBuilder
    private func messageView(for index: Int) -> some View {
        switch index {
        case 0:
            if vehicle.allowed == 0 {
                let msg = NSLocalizedString("You can drive as far as you want because you did not set the mileage allowed.", comment: "")
                messageCard(message: msg, icon: "bolt")
            } else if extendedInfo.maxDriveToday > 0 {
                let format = NSLocalizedString("You can drive up to **%lld** %@ today and still be on track.", comment: "")
                let msg = String(format: format, extendedInfo.maxDriveToday, lengthUnit.shortFor)
                messageCard(message: msg, icon: "bolt")
            } else {
                let exceeded = max(0, extendedInfo.currentMileage - extendedInfo.mileageShouldLessThan)
                let format = NSLocalizedString("You've already exceeded your current pacing by **%lld** %@.", comment: "")
                let msg = String(format: format, exceeded, lengthUnit.shortFor)
                messageCard(message: msg, icon: "bolt")
            }
        case 1:
            let format = NSLocalizedString("Your odometer should read less than **%lld** %@ right now.", comment: "")
            let msg = String(format: format, extendedInfo.mileageShouldLessThan, lengthUnit.shortFor)
            messageCard(message: msg, icon: "gauge.medium")
        case 2:
            let excessCharge = extendedInfo.excessCharge ?? 0
            let currency = vehicle.currency?.uppercased() ?? "USD"
            let msg = excessCharge > 0 ?
                String(format: NSLocalizedString("Estimated excess charge: **%lld** %@ at lease end.", comment: ""), excessCharge, currency) :
                NSLocalizedString("You are currently under your mileage limit. No excess charges estimated.", comment: "")
            
            messageCard(message: msg, icon: "dollarsign.circle")
        default:
            EmptyView()
        }
    }
    
    private func messageCard(message: String, icon: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            .frame(width: 36, height: 36)
            
            if let attributed = try? AttributedString(markdown: message) {
                Text(attributed)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.mainText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(message)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.mainText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
