//
//  VehiclePresentation.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI
import SwiftRater

struct InfoPanel: View {
  var title: Text
  var unit: Text
  var value: Text
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      title
        .foregroundColor(.subText)
      HStack(alignment: .lastTextBaseline) {
        value
          .font(.system(size: 24, weight: .bold, design: .rounded))
        unit
          .foregroundColor(.subText)
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
  }
}

struct MoreInfoView: View {
  var question: Text
  var answer: Text
  var more: Text
  
  @State private var showMore = false
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        question
          .foregroundColor(.subText)
        Button(action: { showMore = true }) {
          Image(systemName: "info.circle").foregroundColor(.subText)
        }.sheet(isPresented: $showMore) {
          more
            .padding()
            .foregroundColor(.subText)
            .presentationDetents([.medium, .fraction(0.4)])
        }
      }
      Spacer().frame(height: 10.0)
      answer
    }
    .listRowBackground(Color.clear)
  }
}

struct VehiclePresentation: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @EnvironmentObject var errorHandler: ErrorHandler
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @AppStorage("showMileageVariance") private var showMileageVariance = true
  @AppStorage("useCircularProgress") private var useCircularProgress = false
  @AppStorage("showGlowEffect") private var showGlowEffect = false
  
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
    List {
      if vehicle.archived {
        Section {
          VStack(alignment: .leading) {
            Text("Archived")
              .font(.caption2).bold()
              .padding(.horizontal, 12).padding(.vertical, 6)
              .background(Color.orange)
              .foregroundColor(.white)
              .cornerRadius(12)
          }
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        }
      }
      Section {
        VStack(alignment: .leading, spacing: 20) {
          // Coach Message
          HStack(spacing: 8) {
            Circle()
              .fill(progressPercentage >= 1.0 ? Color.red : (progressPercentage >= 0.9 ? Color.orange : Color.accentColor))
              .frame(width: 8, height: 8)
              .shadow(color: (progressPercentage >= 1.0 ? Color.red : (progressPercentage >= 0.9 ? Color.orange : Color.accentColor)).opacity(0.5), radius: 4)
            
            Text(extendedInfo.mileageVariance ?? 0 > 0 ? "Heads up — you're over pace" : "Nice pace. You're on track.")
              .font(.system(size: 14, weight: .medium, design: .rounded))
              .foregroundColor(.subText)
          }
          .padding(.horizontal, 4)

          // Gauge
          HStack {
            Spacer()
            GaugeCluster(progress: progressPercentage,
                         projected: extendedInfo.normalPredicatedMileage,
                         variance: extendedInfo.mileageVariance ?? 0,
                         unit: lengthUnit.shortFor)
            Spacer()
          }
          .padding(.vertical, 10)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
      
      // Actions
      // Stats Section
      Section {
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 8) {
            Text("DAILY AVG")
              .font(.system(size: 10, weight: .bold, design: .rounded))
              .foregroundColor(.subText)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
              Text("\(Int(extendedInfo.mileagePerDay))")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.mainText)
              Text(lengthUnit.shortFor)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.subText)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(16)
          .background(Color.subBg)
          .cornerRadius(16)
          
          VStack(alignment: .leading, spacing: 8) {
            Text("ODOMETER")
              .font(.system(size: 10, weight: .bold, design: .rounded))
              .foregroundColor(.subText)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
              Text("\(extendedInfo.currentMileage)")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.mainText)
              Text(lengthUnit.shortFor)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.subText)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(16)
          .background(Color.subBg)
          .cornerRadius(16)
          
          VStack(alignment: .leading, spacing: 8) {
            Text("LEASE LEFT")
              .font(.system(size: 10, weight: .bold, design: .rounded))
              .foregroundColor(.subText)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
              Text("\(extendedInfo.leaseLeft)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.mainText)
              Text("mo")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.subText)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(16)
          .background(Color.subBg)
          .cornerRadius(16)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
      
      // Banner ad
      if !purchaseManager.unlockPro {
        Section {
          BannerAd()
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
      }
      
      Section {
        VStack(alignment: .leading, spacing: 12) {
          Text("TRACKING")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.subText)
            .tracking(1)
          
          Text(vehicle.allowed == 0 ?
               "You can drive as far as you want because you did not set the mileage allowed." :
               "You can drive up to **\(String(extendedInfo.maxDriveToday)) \(lengthUnit.longName.toString())** today and still be on track.")
            .font(.system(size: 16, design: .rounded))
            .foregroundColor(.mainText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subBg.opacity(0.5))
        .cornerRadius(16)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      } footer: {
        Text("disclaimer")
          .font(.system(size: 12.0))
          .foregroundColor(.subText)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .scrollContentBackground(.hidden)
    .listStyle(.plain)
    .safeAreaInset(edge: .bottom) {
      if !vehicle.archived {
        HStack(spacing: 12) {
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
          
          Button(action: {
            showChartSheet.toggle()
          }) {
            Image(systemName: "chart.bar.fill")
              .font(.system(size: 20))
              .frame(width: 56, height: 56)
              .foregroundColor(.mainText)
              .background(Color.subBg)
              .clipShape(Circle())
              .overlay(Circle().stroke(Color.subText.opacity(0.2), lineWidth: 1))
          }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
          LinearGradient(colors: [.black.opacity(0), .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
      }
    }
    .if(showGlowEffect) {
        $0.dangerousZoneGlow(progress: progressPercentage)
    }
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

  private var addReadingButtonLabel: some View {
    HStack {
      if isLoadingTesla {
        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
      } else if isSyncSuccess {
        Image(systemName: "checkmark.circle.fill")
        Text("Done")
      } else {
        Image(systemName: "plus.circle.fill")
        Text("Add Reading")
      }
    }
    .font(.system(size: 16, weight: .bold, design: .rounded))
    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .foregroundColor(.black)
    .background(Color.accentColor)
    .cornerRadius(28)
  }
}
