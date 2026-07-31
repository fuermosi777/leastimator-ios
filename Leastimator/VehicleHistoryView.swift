
import SwiftUI
import CoreData

struct VehicleHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @ObservedObject var vehicle: Vehicle
    
    @State private var selectedRange: HistoryTimeRange = .threeMonths
    @State private var selectedDate: Date? = nil
    @State private var showAllReadings = false
    
    @FetchRequest
    private var readings: FetchedResults<OdoReading>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._readings = FetchRequest(
            entity: OdoReading.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \OdoReading.date, ascending: true)],
            predicate: NSPredicate(format: "vehicle = %@", vehicle)
        )
    }
    
    var historyData: HistoryChartData {
        prepareHistoryChartData(veh: vehicle, readings: Array(readings), range: selectedRange)
    }
    
    var unit: String {
        LengthUnit(rawValue: vehicle.lengthUnit)?.shortFor ?? "mi"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Range Picker
                    HistoryRangePicker(selectedRange: $selectedRange)
                        .padding(.horizontal, 20)
                    
                    // Driven Stats
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DRIVEN · \(historyData.rangeLabel)")
                            .font(.rounded(10, weight: .bold))
                            .kerning(1.5)
                            .foregroundColor(.subText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(historyData.totalDriven)")
                                .font(.rounded(42, weight: .medium))
                                .kerning(-1.5)
                            
                            Text(unit)
                                .font(.rounded(14))
                                .foregroundColor(.subText)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: historyData.isOverPace ? "arrow.up.right" : "arrow.down.right")
                                Text(historyData.isOverPace ? "\(historyData.variancePercent)% over" : "\(historyData.variancePercent)% under")
                            }
                            .font(.rounded(12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(historyData.isOverPace ? Color.statusRed.opacity(0.1) : Color.statusLime.opacity(0.1))
                            .foregroundColor(historyData.isOverPace ? Color.statusRed : Color.statusLime)
                            .cornerRadius(100)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Chart Panel
                    VStack(spacing: 12) {
                        HistoryLineChart(data: historyData, selectedDate: $selectedDate)
                            .padding(.top, 16)
                            .padding(.horizontal, 12)
                        
                        // Legends
                        HStack(spacing: 20) {
                            LegendItem(color: Color.statusAmber, label: "Actual")
                            LegendItem(color: Color.statusAmber.opacity(0.6), label: "Target", isDashed: true)
                        }
                        .padding(.bottom, 16)
                    }
                    .background(Color.subBg.opacity(0.3))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Recent Readings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT READINGS")
                            .font(.rounded(10, weight: .bold))
                            .kerning(1.5)
                            .foregroundColor(.subText)
                            .padding(.bottom, 4)
                        
                        if readings.isEmpty {
                            Text("No readings recorded yet.")
                                .font(.rounded(14))
                                .foregroundColor(.subText)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            let recentList = Array(readings.suffix(5).reversed())
                            ForEach(Array(recentList.enumerated()), id: \.element.id) { index, rd in
                                let originalIdx = readings.firstIndex(of: rd) ?? 0
                                let prev = originalIdx > 0 ? readings[originalIdx - 1] : nil
                                
                                ReadingRowView(reading: rd, previousReading: prev, unit: unit)
                                
                                if index < recentList.count - 1 {
                                    Divider()
                                        .background(Color.mainText.opacity(0.05))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

#if DEBUG
                    BannerAd()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
#else
                    if !purchaseManager.unlockPro {
                        BannerAd()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
#endif
                }
                .padding(.bottom, 40)
            }
            .background(Color.mainBg.ignoresSafeArea())
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.mainText)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAllReadings.toggle() }) {
                        Text("All")
                            .font(.rounded(14, weight: .bold))
                            .foregroundColor(.mainText)
                    }
                }
            }
            .sheet(isPresented: $showAllReadings) {
                ReadingList(vehicle: vehicle)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    var isDashed: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            if isDashed {
                Line()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                    .frame(width: 16, height: 2)
            } else {
                Capsule()
                    .fill(color)
                    .frame(width: 16, height: 3)
            }
            
            Text(label)
                .font(.rounded(11))
                .foregroundColor(.subText)
        }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

#Preview {
    // Note: Needs real vehicle data to preview properly
    Text("Vehicle History Preview")
}
