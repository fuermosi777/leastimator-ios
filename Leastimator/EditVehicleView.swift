//
//  EditVehicleView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/14/21.
//

import SwiftUI
import WidgetKit

struct LSTextField: View {
  let label: String
  let placeholder: String
  let keyboardType: UIKeyboardType
  let unit: String?
  let isNumeric: Bool
  let isDisabled: Bool
  
  @Binding var value: String
  
  init(label: String, placeholder: String, keyboardType: UIKeyboardType = .default, unit: String? = nil, isNumeric: Bool = false, isDisabled: Bool = false, value: Binding<String>) {
    self.label = label
    self.placeholder = placeholder
    self.keyboardType = keyboardType
    self.unit = unit
    self.isNumeric = isNumeric
    self.isDisabled = isDisabled
    self._value = value
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label.uppercased())
        .font(.rounded(10, weight: .bold))
        .foregroundColor(.subText)
        .tracking(1.5)
      
      HStack(spacing: 8) {
        TextField(placeholder, text: $value)
          .font(isNumeric ? .rounded(15) : .rounded(15))
          .foregroundColor(isDisabled ? .subText : .mainText)
          .keyboardType(keyboardType)
          .disabled(isDisabled)
        
        if let unit = unit {
          Text(unit)
            .font(.rounded(12))
            .foregroundColor(.subText)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.subBg.opacity(0.3))
      .cornerRadius(14)
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
      )
    }
    .opacity(isDisabled ? 0.6 : 1.0)
  }
}

let kUnknownVehicleName = "Unknown Vehicle"

// A view used to create or edit a Vehicle data model.
struct EditVehicleView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject var errorHandler: ErrorHandler
  @EnvironmentObject var purchaseManager: PurchaseManager
  
  @State private var showTeslaPicker = false
  @State private var availableTeslaVehicles: [TeslaVehicle] = []
  @State private var isLoadingTesla = false
  @State private var showProUpgradeSheet = false
  
  // Optional. If not exist, then create a new vehicle.
  var vehicle: Vehicle?
  
  @State private var name: String
  @State private var starting: String
  @State private var allowed: String
  @State private var lengthOfLease: String
  @State private var startDate: Date
  @State private var fee: String
  @State private var image: Data?
  @State private var lengthUnit: LengthUnit
  @State private var currency: String
  
  @State private var showImagePicker = false
  @State private var showDeletionWarning = false
  
  init(vehicle: Vehicle? = nil) {
    self.vehicle = vehicle
    
    if let vehicle = vehicle {
      _name = State(initialValue: vehicle.name ?? kUnknownVehicleName)
      _starting = State(initialValue: vehicle.starting != 0 ? String(vehicle.starting) : "")
      _allowed = State(initialValue: vehicle.allowed != 0 ? String(vehicle.allowed) : "")
      _lengthOfLease = State(initialValue: vehicle.lengthOfLease != 0 ? String(vehicle.lengthOfLease) : "")
      _startDate = State(initialValue: vehicle.startDate ?? Date())
      _fee = State(initialValue: vehicle.fee != 0 ? String(vehicle.fee) : "")
      _image = State(initialValue: vehicle.image)
      if let initialValue = LengthUnit(rawValue: vehicle.lengthUnit) {
        _lengthUnit = State(initialValue: initialValue)
      } else {
        _lengthUnit = State(initialValue: .Imperial)
      }
    } else {
      _name = State(initialValue: "")
      _starting = State(initialValue: "")
      _allowed = State(initialValue: "")
      _lengthOfLease = State(initialValue: vehicle != nil ? String(vehicle!.lengthOfLease) : "")
      _startDate = State(initialValue: Date())
      _fee = State(initialValue: "")
      _image = State(initialValue: nil)
      _lengthUnit = State(initialValue: .Imperial)
    }
    
    _currency = State(initialValue: vehicle != nil ?
                      vehicle!.currency ?? Currency.usd.rawValue
                      : Currency.usd.rawValue)
  }
  
  var extendedInfo: ExtendedVehicleInfo? {
    if let vehicle = vehicle {
      return Compute(vehicle)
    }
    return nil
  }
  
  var progressPercentage: Float {
    guard let info = extendedInfo, let vehicle = vehicle else { return 0 }
    let up = Float(info.normalPredicatedMileage)
    let down = Float(vehicle.allowed + vehicle.starting)
    if down > 0 {
      return min(Float(up / down), 1.0)
    }
    return 1.0
  }
  
  private var statusColor: Color {
    if vehicle == nil { return .statusLime }
    return Color.statusColor(progress: Double(progressPercentage))
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.mainBg.ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Custom Header
        HStack {
          Button { dismiss() } label: {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.mainText)
              .frame(width: 32, height: 32)
              .background(Color.mainText.opacity(0.05))
              .clipShape(Circle())
          }
          
          Spacer()
          
          Text(vehicle != nil ? (vehicle?.name ?? "Edit Vehicle") : "Add Vehicle")
            .font(.rounded(17, weight: .bold))
          
          Spacer()
          
          // Invisible spacer for balance
          Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)

        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            // Basic Info
            VStack(spacing: 16) {
              LSTextField(label: "Nickname", placeholder: "My car", value: $name)
              
              LSTextField(label: "Starting mileage", placeholder: "20", keyboardType: .numberPad, unit: lengthUnit.shortFor, isNumeric: true, value: $starting)
              
              LSTextField(label: "Total mileage allowed", placeholder: "30000", keyboardType: .numberPad, unit: lengthUnit.shortFor, isNumeric: true, value: $allowed)
              
              LSTextField(label: "Length of lease", placeholder: "36", keyboardType: .numberPad, unit: "mo", isNumeric: true, value: $lengthOfLease)
              
              DateCard(label: "Lease start date", selection: $startDate)
            }
            
            // Advanced Info
            VStack(spacing: 16) {
              LSTextField(label: "Overage fee", placeholder: "0.25", keyboardType: .decimalPad, unit: "\(currency)/\(lengthUnit.shortFor)", isNumeric: true, value: $fee)
              
              PickerCard(label: "Length unit", selection: $lengthUnit) {
                Picker("Length unit", selection: $lengthUnit) {
                  ForEach(LengthUnit.allCases, id: \.rawValue) { value in
                    Text(value.longName).tag(value)
                  }
                }
                .pickerStyle(.segmented)
              }
              
              PickerCard(label: "Currency", selection: $currency) {
                Picker("Currency", selection: $currency) {
                  ForEach(Currency.allCases, id: \.rawValue) { value in
                    Text(value.rawValue).tag(value.rawValue)
                  }
                }
                .pickerStyle(.segmented)
              }
            }
            
            if vehicle != nil {
              // Tesla Integration
              VStack(alignment: .leading, spacing: 12) {
                Text("TESLA INTEGRATION (PRO)")
                  .font(.rounded(10, weight: .bold))
                  .foregroundColor(.subText)
                  .tracking(1.5)
                
                VStack {
                  if purchaseManager.unlockPro {
                    if let teslaId = vehicle?.teslaVehicleId, !teslaId.isEmpty {
                      if let connId = vehicle?.teslaConnectionId, KeychainHelper.shared.load(for: connId) != nil {
                        HStack {
                          Label("Connected to Tesla", systemImage: "checkmark.circle.fill")
                            .font(.rounded(14, weight: .semibold))
                            .foregroundColor(.green)
                          Spacer()
                          if isLoadingTesla {
                            ProgressView()
                          } else {
                            Button("Disconnect") { disconnectTesla() }
                              .font(.rounded(14, weight: .bold))
                              .foregroundColor(.statusRed)
                          }
                        }
                      } else {
                        VStack(alignment: .leading, spacing: 8) {
                          Text("You must sign in again to sync.")
                            .font(.rounded(13, weight: .medium))
                            .foregroundColor(.statusAmber)
                          if isLoadingTesla {
                            ProgressView()
                          } else {
                            Button("Log in to Tesla") { connectTesla() }
                              .font(.rounded(14, weight: .bold))
                              .foregroundColor(statusColor)
                          }
                        }
                      }
                    } else {
                      if isLoadingTesla {
                        ProgressView()
                      } else {
                        Button { connectTesla() } label: {
                          HStack {
                            Image(systemName: "bolt.fill")
                            Text("Connect to Tesla")
                          }
                          .font(.rounded(14, weight: .bold))
                          .foregroundColor(statusColor)
                        }
                      }
                    }
                  } else {
                    Button(action: {
                      showProUpgradeSheet = true
                    }) {
                      HStack {
                        Label("Connect to Tesla", systemImage: "bolt.fill")
                          .font(.rounded(14, weight: .semibold))
                          .foregroundColor(.subText)
                        Spacer()
                        ProBadge()
                      }
                    }
                    .buttonStyle(.plain)
                  }
                }
                .padding(16)
                .background(Color.subBg.opacity(0.3))
                .cornerRadius(16)
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
                )
              }
              
              Button(action: { showDeletionWarning.toggle() }) {
                HStack {
                  Image(systemName: "trash")
                  Text("Delete Vehicle")
                }
                .font(.rounded(15, weight: .semibold))
                .foregroundColor(.statusRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.statusRed.opacity(0.1))
                .cornerRadius(16)
              }
              .padding(.top, 8)
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 10)
          .padding(.bottom, 120) // Space for sticky button
        }
      }
      
      // Sticky Bottom Button
      VStack(spacing: 0) {
        LinearGradient(colors: [.clear, Color.mainBg.opacity(0.8), Color.mainBg], startPoint: .top, endPoint: .bottom)
          .frame(height: 40)
        
        Button(action: {
          do {
            try self.handleSave()
          } catch {
            self.errorHandler.handle(error)
          }
        }) {
          Text(vehicle == nil ? "Add Vehicle" : "Save Changes")
            .font(.rounded(16, weight: .bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(statusColor)
            .cornerRadius(28)
            .shadow(color: statusColor.opacity(0.3), radius: 15, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
        .background(Color.mainBg)
        .disabled(isSaveDisabled)
        .opacity(isSaveDisabled ? 0.5 : 1.0)
      }
    }
    .sheet(isPresented: $showTeslaPicker, onDismiss: { showTeslaPicker = false }){
      TeslaVehiclePicker(vehicles: availableTeslaVehicles, existingVehicleId: vehicle?.teslaVehicleId) { selectedVehicle in
        vehicle?.teslaVehicleId = selectedVehicle.id
        try? viewContext.save()
        showTeslaPicker = false
        Task { await initialWakeAndSync() }
      } onCancel: {
        showTeslaPicker = false
      }
    }
    .sheet(isPresented: $showProUpgradeSheet) {
      ProProductsView()
        .withErrorHandler()
    }
    .alert("vehicle delete warning message",
           isPresented: $showDeletionWarning) {
      Button("Delete", role: .destructive) {
        do {
          try handleDelete()
        } catch {
          self.errorHandler.handle(error)
        }
      }
      Button("Cancel", role: .cancel) {}
    }
  }

  private func PickerCard<V: Hashable, Content: View>(label: String, selection: Binding<V>, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label.uppercased())
        .font(.rounded(10, weight: .bold))
        .foregroundColor(.subText)
        .tracking(1.5)
      
      content()
        .padding(4)
        .background(Color.subBg.opacity(0.3))
        .cornerRadius(14)
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
        )
    }
  }

  private func DateCard(label: String, selection: Binding<Date>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label.uppercased())
        .font(.rounded(10, weight: .bold))
        .foregroundColor(.subText)
        .tracking(1.5)
      
      HStack {
        DatePicker(label, selection: selection, in: ...Date(), displayedComponents: .date)
          .labelsHidden()
          .tint(statusColor)
        Spacer()
        Image(systemName: "calendar")
          .font(.system(size: 16))
          .foregroundColor(.subText)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.subBg.opacity(0.3))
      .cornerRadius(14)
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
      )
    }
  }
  
  private func connectTesla() {
      guard let vehicle = self.vehicle else { return }
      Task {
          do {
              await MainActor.run { isLoadingTesla = true }
              let tokens = try await TeslaAuthManager.shared.authenticate()
              let connId = vehicle.teslaConnectionId ?? UUID().uuidString
              
              KeychainHelper.shared.save(tokens, for: connId)
              
              let service = TeslaService(connectionId: connId)
              // Discover the account's Fleet API region up front so subsequent
              // calls go straight to the right host (UK/EU users etc.).
              await service.resolveRegionIfNeeded()
              let list = try await service.getVehicles()
              
              await MainActor.run {
                  vehicle.teslaConnectionId = connId
                  self.availableTeslaVehicles = list
                  self.isLoadingTesla = false
                  self.showTeslaPicker = true
                  Logger.shared.teslaConnectSuccess(vehicleCount: list.count)
              }
          } catch {
              await MainActor.run {
                  self.isLoadingTesla = false
                  self.errorHandler.handle(error)
              }
          }
      }
  }
  
  private func disconnectTesla() {
      guard let vehicle = self.vehicle else { return }
      if let connId = vehicle.teslaConnectionId {
          KeychainHelper.shared.delete(for: connId)
          TeslaRegionStore.clear(for: connId)
      }
      vehicle.teslaVehicleId = nil
      vehicle.teslaConnectionId = nil
      try? viewContext.save()
  }
  
  private func initialWakeAndSync() async {
      guard let vehicle = self.vehicle, let vid = vehicle.teslaVehicleId, let cid = vehicle.teslaConnectionId else { return }
      let service = TeslaService(connectionId: cid)
      do {
          await MainActor.run { isLoadingTesla = true }
          // Force wake up on first-time setup
          try await service.wakeUp(vehicleId: vid)
          try await Task.sleep(nanoseconds: 3_000_000_000)
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
              isLoadingTesla = false
          }
      } catch {
          // The vehicle is already linked at this point; a failed wake/read just
          // means the car is asleep or briefly unavailable. The next background
          // sync will pick up the odometer once it's online. Log it, but don't
          // alarm the user with an error — the connection itself succeeded.
          Logger.shared.teslaAPIError("initialWakeAndSync", error)
          await MainActor.run {
              isLoadingTesla = false
          }
      }
  }



  private func handleDelete() throws {
    if let vehicle = self.vehicle {
      vehicle.removed = true

      do {
        try viewContext.save()
      } catch {
        throw AppError.failedContextSave
      }

      Logger.shared.vehicleDeleted()
      dismiss()
    }
  }
  
  var isSaveDisabled: Bool {
    return name.isEmpty ||
    starting.isEmpty ||
    lengthOfLease.isEmpty
  }
  
  // TODO: localize error reasons.
  private func handleSave() throws {
    let allowedNumber: Int64
    let feeNumber: Float
    let lengthOfLeaseNumber: Int64
    
    guard name.count > 0 else {
      throw AppError.invalidInput(reason: "Name is empty")
    }
    
    if allowed != "" {
      guard let allowed = Int(allowed) else {
        throw AppError.invalidInput(reason: "Allowed mileage is not a valid number")
      }
      allowedNumber = Int64(allowed)
    } else {
      // If there is not allowed mileage, set it to zero.
      allowedNumber = 0
    }
    if fee != "" {
      guard let fee = Float(fee) else {
        throw AppError.invalidInput(reason: "Fee is not a valid number")
      }
      feeNumber = fee
    } else {
      feeNumber = 0
    }
    
    guard let starting = Int(starting) else {
      throw AppError.invalidInput(reason: "Starting mileage is not a valid number")
    }
    if starting < 0 {
      throw AppError.invalidInput(reason: "Starting mileage should be larger than 0")
    }
    guard let lengthOfLease = Int(lengthOfLease) else {
      throw AppError.invalidInput(reason: "Length of lease is not a valid number")
    }
    if lengthOfLease <= 0 {
      throw AppError.invalidInput(reason: "Length of lease should be larger than 0")
    }
    if lengthOfLease > 120 {
      throw AppError.invalidInput(reason: "Sorry, a lease with a term longer than 10 years is not supported for now")
    }
    lengthOfLeaseNumber = Int64(lengthOfLease)

    
    let isNew = self.vehicle == nil
    let vehicle = self.vehicle ?? Vehicle(context: viewContext)
    vehicle.allowed = allowedNumber
    vehicle.fee = feeNumber
    vehicle.lengthOfLease = lengthOfLeaseNumber
    
    vehicle.name = name
    vehicle.starting = Int64(starting)
    vehicle.startDate = startDate
    vehicle.image = image
    vehicle.lengthUnit = lengthUnit.rawValue
    vehicle.currency = currency
    
    do {
      try viewContext.save()
    } catch {
      throw AppError.failedContextSave
    }

    if isNew { Logger.shared.vehicleCreated() }
    dismiss()
  }
}
