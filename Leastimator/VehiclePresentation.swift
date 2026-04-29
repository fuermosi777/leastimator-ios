//
//  VehiclePresentation.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI
import SwiftRater

struct VehiclePresentation: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @EnvironmentObject var errorHandler: ErrorHandler
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @AppStorage("showMileageVariance") private var showMileageVariance = true
  
  // Add ObservedObject make sure it gets updated data.
  @ObservedObject var vehicle: Vehicle
  
  @State private var dashboardIndex = 0
  
  @State var chartTapValue: Int? = 0
  
  @State var graphType: GraphType = .monthly
  
  @State private var showAddReadingSheet = false
  @State private var showChartSheet = false
  @State private var showSleepAlert = false
  @State private var showCooldownAlert = false
  @State private var isLoadingTesla = false
  @State private var isSyncSuccess = false
  @State private var vehicleState: String?
  
  enum GraphType {
    case monthly, daily
  }
  
  init(vehicle: Vehicle) {
    self.vehicle = vehicle
  }
  
  var extendedInfo: ExtendedVehicleInfo {
    return Compute(vehicle)
  }
  
  var lengthUnit: LengthUnit {
    get {
      if let unit = LengthUnit(rawValue: vehicle.lengthUnit) {
        return unit
      } else {
        return .Imperial
      }
    }
  }
  
  var currency: Currency {
    get {
      if let curr = Currency(rawValue: vehicle.currency ?? "usd") {
        return curr
      } else {
        return Currency.usd
      }
    }
  }
  
  var progressPercentage: Float {
    let up = Float(extendedInfo.normalPredicatedMileage)
    let down = Float(vehicle.allowed + vehicle.starting)
    if down > 0 {
      return min(Float(up / down), 1.0)
    }
    return 1.0
  }
  
  private var statusColor: Color {
    Color.statusColor(progress: Double(progressPercentage))
  }
  
  let linearGradient = LinearGradient(
    gradient: Gradient (
      colors: [
        .accentColor.opacity(0.6),
        .accentColor.opacity(0.4),
        .accentColor.opacity(0.0),
      ]
    ),
    startPoint: .top, endPoint: .bottom)
  
  
  var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          if vehicle.archived {
            Text("Archived")
              .font(.inter(11, weight: .bold))
              .padding(.horizontal, 12).padding(.vertical, 6)
              .background(Color.orange)
              .foregroundColor(.white)
              .cornerRadius(12)
              .padding(.top, 8)
          }

          HStack(alignment: .center) {
            CoachMessage(isOverPace: progressPercentage >= 1.0)
            Spacer()
            if vehicle.teslaConnectionId != nil {
              TeslaAPIStatusView(state: vehicleState)
            }
          }
          .padding(.top, vehicle.archived ? 0 : 8)

          // Big gauge
          HStack {
            Spacer()
            DashboardGauge(
              progress: Double(progressPercentage),
              projected: extendedInfo.normalPredicatedMileage,
              variance: extendedInfo.mileageVariance ?? 0,
              unit: lengthUnit.shortFor,
              statusColor: statusColor
            )
            Spacer()
          }
          .padding(.vertical, 10)

          // Track info card
          HStack(alignment: .center, spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 22))
                .foregroundColor(statusColor)
                .shadow(color: statusColor.opacity(0.3), radius: 5)
            
            Text(vehicle.allowed == 0 ?
                 "You can drive as far as you want because you did not set the mileage allowed." :
                 "You can drive up to \(String(extendedInfo.maxDriveToday)) \(lengthUnit.longName.toString()) today and still be on track.")
            .font(.inter(16, weight: .bold))
            .foregroundColor(.mainText)
            .fixedSize(horizontal: false, vertical: true)
          }
          .padding(20)
          .background(Color.subBg.opacity(0.3))
          .cornerRadius(24)
          .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
          )

          // Primary stats grid in a single tile
          HStack(spacing: 0) {
            StatCell(label: "DAILY AVG", value: String(format: "%.0f", extendedInfo.mileagePerDay), unit: lengthUnit.shortFor)
            
            Divider()
              .frame(height: 32)
              .padding(.horizontal, 2)
            
            StatCell(label: "ODOMETER", value: "\(extendedInfo.currentMileage)", unit: lengthUnit.shortFor)
            
            Divider()
              .frame(height: 32)
              .padding(.horizontal, 2)
            
            StatCell(label: "LEASE LEFT", value: "\(extendedInfo.leaseLeft)", unit: "mo")
          }
          .padding(.vertical, 16)
          .padding(.trailing, 12)
          .background(Color.subBg.opacity(0.3))
          .cornerRadius(16)
          .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
          )

          if !purchaseManager.unlockPro {
            BannerAd()
              .padding(.vertical, 8)
          }
          
          Text("Calculations are estimates based on your lease terms and driving history.")
            .font(.inter(11))
            .foregroundColor(.subText)
            .padding(.top, 8)
            .padding(.bottom, 120) // Spacer for sticky buttons
        }
        .padding(.horizontal, 24)
      }
      .scrollIndicators(.hidden)

      // Sticky Bottom Buttons
      HStack(spacing: 12) {
        if !vehicle.archived {
          addReadingButton
        }
        
        Button(action: {
          showChartSheet.toggle()
        }) {
          Image(systemName: "chart.bar.fill")
            .font(.system(size: 18))
            .foregroundColor(.mainText)
            .frame(width: 56, height: 56)
            .background(Color.subBg)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 34) // Adjust for safe area
      .background(
        LinearGradient(colors: [.clear, Color.mainBg.opacity(0.8), Color.mainBg], startPoint: .top, endPoint: .bottom)
            .frame(height: 140)
            .ignoresSafeArea()
      )
    }
    .scrollContentBackground(.hidden)
    .listStyle(.plain)
    .sheet(isPresented: $showAddReadingSheet) {
      EditReadingView(vehicle: vehicle)
        .withErrorHandler()
    }
    .sheet(isPresented: $showChartSheet) {
      ChartSheetView(extendedInfo: extendedInfo, vehicle: vehicle)
    }
    .alert("Notice", isPresented: $showSleepAlert) {
      Button("Add Manually") { showAddReadingSheet.toggle() }
      Button("OK", role: .cancel) {}
    } message: {
      Text("Vehicle is asleep. Leastimator avoids waking it to save battery and API costs. It will automatically sync next time the vehicle is active, or you can add a reading manually right now.")
    }
    .alert("Sync Cooldown", isPresented: $showCooldownAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("To minimize API costs, Tesla sync is limited to once every \(AppConstants.teslaSyncCooldownHours) hours. Please try again later.")
    }
    .onAppear {
      Logger.shared.vehiclePageView()
      SwiftRater.check()
      if vehicle.teslaConnectionId != nil {
          Task { await pollTeslaState() }
      }
    }
    .onReceive(Timer.publish(every: 180, on: .main, in: .common).autoconnect()) { _ in
        if vehicle.teslaConnectionId != nil {
            Task { await pollTeslaState() }
        }
    }
  }
  
  private func syncIfOnline() async {
      if let lastSync = vehicle.lastTeslaSyncDate,
         Date().timeIntervalSince(lastSync) < AppConstants.teslaSyncCooldownSeconds {
          await MainActor.run { showCooldownAlert = true }
          return
      }
      guard let vid = vehicle.teslaVehicleId, let cid = vehicle.teslaConnectionId else { return }
      let service = TeslaService(connectionId: cid)
      do {
          await MainActor.run { isLoadingTesla = true }
          let list = try await service.getVehicles()
          if let myVehicle = list.first(where: { $0.id == vid }) {
              let state = myVehicle.state.lowercased()
              await MainActor.run { self.vehicleState = state }
              if state == "online" {
                  let data = try await service.getVehicleData(vehicleId: vid)
                  let odo = data.vehicle_state.odometer
                  var value = odo
                  if vehicle.lengthUnit == LengthUnit.Metric.rawValue {
                      value = odo * 1.60934
                  }
                  await MainActor.run {
                      let reading = OdoReading(context: viewContext)
                      reading.value = Int64(value)
                      reading.date = Date()
                      reading.vehicle = vehicle
                      try? viewContext.save()
                      vehicle.updateLastTeslaSyncDate()
                      isLoadingTesla = false
                      isSyncSuccess = true
                      
                      // Result indicator delay
                      Task {
                          try? await Task.sleep(nanoseconds: 3 * 1_000_000_000) // 3 seconds
                          await MainActor.run { isSyncSuccess = false }
                      }
                  }
              } else {
                  await MainActor.run {
                      isLoadingTesla = false
                      showSleepAlert = true
                  }
              }
          } else {
              await MainActor.run { isLoadingTesla = false }
          }
      } catch {
          await MainActor.run {
              isLoadingTesla = false
              self.errorHandler.handle(error)
          }
      }
  }
  
  private func pollTeslaState() async {
      if let lastSync = vehicle.lastTeslaSyncDate,
         Date().timeIntervalSince(lastSync) < AppConstants.teslaSyncCooldownSeconds {
          return
      }
      guard let vid = vehicle.teslaVehicleId, let cid = vehicle.teslaConnectionId else { return }
      let service = TeslaService(connectionId: cid)
      do {
          let list = try await service.getVehicles()
          if let myVehicle = list.first(where: { $0.id == vid }) {
              let state = myVehicle.state.lowercased()
              await MainActor.run { self.vehicleState = state }
              
              if state == "online" {
                  let data = try await service.getVehicleData(vehicleId: vid)
                  let odo = data.vehicle_state.odometer
                  var value = odo
                  if vehicle.lengthUnit == LengthUnit.Metric.rawValue {
                      value = odo * 1.60934
                  }
                  await MainActor.run {
                      let reading = OdoReading(context: viewContext)
                      reading.value = Int64(value)
                      reading.date = Date()
                      reading.vehicle = vehicle
                      try? viewContext.save()
                      vehicle.updateLastTeslaSyncDate()
                  }
              }
          }
      } catch {
          // Silent fail for background polling
      }
  }

  private var addReadingButton: some View {
    Group {
      if vehicle.teslaConnectionId != nil {
        Menu {
          Button {
            Task { await syncIfOnline() }
          } label: {
            Label("Auto Sync from Tesla", systemImage: "arrow.triangle.2.circlepath")
          }
          Button {
            showAddReadingSheet.toggle()
          } label: {
            Label("Add Manually", systemImage: "keyboard")
          }
        } label: {
          addReadingButtonLabel
        }
      } else {
        Button(action: {
          showAddReadingSheet.toggle()
        }) {
          addReadingButtonLabel
        }
      }
    }
    .disabled(isLoadingTesla || isSyncSuccess)
  }

  private var addReadingButtonLabel: some View {
    HStack(spacing: 8) {
      if isLoadingTesla {
        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
      } else if isSyncSuccess {
        Image(systemName: "checkmark.circle.fill")
        Text("Done")
      } else {
        Image(systemName: "plus")
        Text("Add Reading")
      }
    }
    .font(.inter(16, weight: .bold))
    .foregroundColor(.black)
    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .background(statusColor)
    .cornerRadius(28)
    .shadow(color: statusColor.opacity(0.3), radius: 15, y: 5)
  }
}
