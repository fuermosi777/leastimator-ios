//
//  EditVehicleView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/14/21.
//

import SwiftUI
import WidgetKit

struct LSTextField: View {
  let label: Text
  let placeholder: LocalizedStringKey
  let keyboardType: UIKeyboardType
  
  @Binding var value: String
  
  var body: some View {
    HStack {
      label
      TextField(self.placeholder, text: $value).multilineTextAlignment(.trailing)
        .keyboardType(keyboardType)
    }
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
  
  var body: some View {
    NavigationStack {
      List {
        Section {
          Menu {
            Button { showImagePicker.toggle() } label: {
              Text("Upload from Photos")
            }
            Button { image = nil } label: {
              Text("Remove")
            }
          } label: {
            VStack {
              HStack(alignment: .center) {
                Spacer()
                VehicleImage(data: image, size: 140.0)
                Spacer()
              }
              
              Text("Select Vehicle Photo")
                .foregroundColor(.subText)
            }
          }
        }.listRowBackground(Color.clear)
        
        Section {
          LSTextField(label: Text("Nickname"),
                      placeholder: LocalizedStringKey("My car"),
                      keyboardType: .default,
                      value: $name)
          
          LSTextField(label: Text("Starting mileage"),
                      placeholder: LocalizedStringKey("20"),
                      keyboardType: .numberPad,
                      value: $starting)
          
          LSTextField(label: Text("Total mileage allowed"),
                      placeholder: LocalizedStringKey("30000"),
                      keyboardType: .numberPad,
                      value: $allowed)
          
          LSTextField(label: Text("Length of lease"),
                      placeholder: LocalizedStringKey("36"),
                      keyboardType: .numberPad,
                      value: $lengthOfLease)
          
          DatePicker(selection: $startDate,
                     in: ...Date(),
                     displayedComponents: .date) {
            Text("Lease start date")
          }
        }
        
        Section {
          LSTextField(label: Text("Overage fee"),
                      placeholder: LocalizedStringKey("0.25"),
                      keyboardType: .decimalPad,
                      value: $fee)
          HStack {
            Text("Length unit")
            Spacer()
            Picker("Length unit", selection: $lengthUnit) {
              ForEach(LengthUnit.allCases, id: \.rawValue) { value in
                Text(value.longName).tag(value)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
          }
          HStack {
            Text("Currency")
            Spacer()
            Picker("Curreny", selection: $currency) {
              ForEach(Currency.allCases, id: \.rawValue) { value in
                Text(value.rawValue).tag(value.rawValue)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
          }
        }
        
        if vehicle != nil {
          Section(header: Text("Tesla Integration (Pro)")) {
            if purchaseManager.unlockPro {
              if let teslaId = vehicle?.teslaVehicleId, !teslaId.isEmpty {
                  if let connId = vehicle?.teslaConnectionId, KeychainHelper.shared.load(for: connId) != nil {
                      HStack {
                          Text("Connected to Tesla")
                              .foregroundColor(.green)
                          Spacer()
                          if isLoadingTesla {
                              ProgressView()
                          } else {
                              Button("Disconnect") {
                                  disconnectTesla()
                              }
                              .foregroundColor(.red)
                          }
                      }
                  } else {
                      VStack(alignment: .leading, spacing: 8) {
                          Text("You must sign in again on this device to sync Tesla data.")
                              .font(.caption)
                              .foregroundColor(.orange)
                          if isLoadingTesla {
                              ProgressView()
                          } else {
                              Button("Log in to Tesla") {
                                  connectTesla()
                              }
                          }
                      }
                  }
              } else {
                  if isLoadingTesla {
                      ProgressView()
                  } else {
                      Button("Connect to Tesla") {
                          connectTesla()
                      }
                  }
              }
            } else {
               HStack {
                   Text("Connect to Tesla")
                      .foregroundColor(.secondary)
                   Spacer()
                   ProBadge()
               }
            }
          }
          
          Section {
            Button {
              showDeletionWarning.toggle()
            } label: {
              Label("Delete", systemImage: "trash")
                .foregroundColor(.red)
            }
          }
        }
      }
      .navigationBarTitle(Text(vehicle?.name ?? "Add Vehicle"),
                          displayMode: .inline)
      .navigationBarItems(
        leading:
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          },
        trailing:
          Button("Save") {
            do {
              try self.handleSave()
            } catch {
              self.errorHandler.handle(error)
            }
          }.disabled(isSaveDisabled)
      )
      .sheet(isPresented: $showImagePicker, onDismiss: { showImagePicker = false }){
        ImagePicker(sourceType: .photoLibrary) { picked in
          let resized = picked.resizeImage(CGFloat(200), opaque: false)
          image = resized.pngData()
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
              let list = try await service.getVehicles()
              
              await MainActor.run {
                  vehicle.teslaConnectionId = connId
                  self.availableTeslaVehicles = list
                  self.isLoadingTesla = false
                  self.showTeslaPicker = true
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
          await MainActor.run {
              isLoadingTesla = false
              self.errorHandler.handle(error)
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
    
    dismiss()
  }
}
