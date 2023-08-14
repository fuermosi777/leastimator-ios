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
  
  // Optional. If not exist, then create a new vehicle.
  var vehicle: Vehicle?
  
  @State private var name: String
  @State private var starting: String
  @State private var allowed: String
  @State private var lengthOfLease: String
  @State private var startDate: Date
  @State private var fee: String
  @State private var avatar: Data?
  @State private var lengthUnit: LengthUnit
  @State private var currency: String
  
  @State private var showAvatarPicker = false
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
      _avatar = State(initialValue: vehicle.avatar)
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
      _avatar = State(initialValue: nil)
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
            Button { showAvatarPicker.toggle() } label: {
              Text("Upload from Photos")
            }
            Button { avatar = nil } label: {
              Text("Remove")
            }
          } label: {
            VStack {
              HStack(alignment: .center) {
                Spacer()
                VehicleAvatar(data: avatar)
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
      .sheet(isPresented: $showAvatarPicker){
        ImagePicker(sourceType: .photoLibrary) {image in
          let resized = image.resizeImage(CGFloat(200), opaque: true)
          avatar = resized.pngData()
          showAvatarPicker = false
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
    vehicle.avatar = avatar
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
