//
//  EditVehicleView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/14/21.
//

import SwiftUI

struct LSTextField: View {
  let label: String
  let placeholder: String
  let keyboardType: UIKeyboardType
  
  @Binding var value: String
  
  var body: some View {
    HStack {
      Text(self.label)
      TextField(self.placeholder, text: $value).multilineTextAlignment(.trailing)
        .keyboardType(keyboardType)
    }
  }
}

// A view used to create or edit a Vehicle data model.
struct EditVehicleView: View {
  @Environment(\.managedObjectContext) private var viewContext
  
  // Optional. If not exist, then create a new vehicle.
  var vehicle: Vehicle?
  var onDismiss: () -> Void
  
  @State private var name: String
  @State private var starting: String
  @State private var allowed: String
  @State private var lengthOfLease: String
  @State private var startDate: Date
  @State private var fee: String
  @State private var avatar: Data?
  @State private var lengthUnit: LengthUnit
  @State private var currency: String
  
  @State private var showAlert = false
  @State private var alertMessage: String?
  @State private var showAvatarPicker = false
  
  init(vehicle: Vehicle? = nil, onDismiss: @escaping () -> Void) {
    self.vehicle = vehicle
    _name = State(initialValue: vehicle?.name ?? "")
    _starting = State(initialValue: vehicle != nil ? String(vehicle!.starting) : "")
    _allowed = State(initialValue: vehicle != nil ? String(vehicle!.allowed) : "")
    _lengthOfLease = State(initialValue: vehicle != nil ? String(vehicle!.lengthOfLease) : "")
    _startDate = State(initialValue: vehicle?.startDate ?? Date())
    _fee = State(initialValue: vehicle != nil ? String(vehicle!.fee) : "")
    _avatar = State(initialValue: vehicle != nil ? vehicle!.avatar : nil)
    if let vehicle = vehicle {
      if let initialValue = LengthUnit(rawValue: vehicle.lengthUnit) {
        _lengthUnit = State(initialValue: initialValue)
      } else {
        _lengthUnit = State(initialValue: .mi)
      }
    } else {
      _lengthUnit = State(initialValue: .mi)
    }
    
    _currency = State(initialValue: vehicle != nil ?
                        vehicle!.currency ?? Currency.usd.rawValue
                        : Currency.usd.rawValue)
    self.onDismiss = onDismiss
  }
  
  var body: some View {
    NavigationView {
      ScrollView {
        Button(action: { self.showAvatarPicker = true }) {
          if let avatarData = avatar {
            VehicleAvatar(data: avatarData)
          } else {
            Label("Select vehicle photo", systemImage: "plus")
          }
        }
        
        
        Group {
          LSTextField(label: "Nickname",
                      placeholder: "My ride",
                      keyboardType: .default,
                      value: $name)
          Divider()
          LSTextField(label: "Starting mileage",
                      placeholder: "20",
                      keyboardType: .numberPad,
                      value: $starting)
          Divider()
          LSTextField(label: "Mileage allowed",
                      placeholder: "30000",
                      keyboardType: .numberPad,
                      value: $allowed)
          Divider()
          LSTextField(label: "Length of lease",
                      placeholder: "36",
                      keyboardType: .numberPad,
                      value: $lengthOfLease)
          Divider()

          DatePicker(selection: $startDate,
                     in: ...Date(),
                     displayedComponents: .date) {
            Text("Lease start date")
          }
          Divider()
        }
        
        Group {
          LSTextField(label: "Over fee",
                      placeholder: "0.25",
                      keyboardType: .decimalPad,
                      value: $fee)
          Divider()
        }
        
        Group {
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
          Divider()
        }
        
        Group {
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
          Divider()
        }
        
        if vehicle != nil {
          Spacer().frame(height: 20)
          Button(action: handleDelete) {
            Image(systemName: "trash").foregroundColor(Color.red)
          }
        }
        
        Spacer()
        
      }  // ScrollView
      .padding(10.0)
      .navigationBarTitle(Text(vehicle?.name ?? "Add vehicle"),
                          displayMode: .inline)
      .navigationBarItems(
        leading:
          Button(action: { self.onDismiss() }) {
            Image(systemName: "xmark")
          },
        trailing:
          Button("Done") {
            do {
              try self.handleDone()
            } catch AppError.invalidInput(let reason) {
              self.showAlert = true
              self.alertMessage = "One of the inputs seems to be incorrect: \(reason)"
            } catch AppError.failedContextSave {
              self.showAlert = true
              self.alertMessage = "Failed to save changes. Please quit the app and try again."
            } catch {
              print(error)
            }
          }
      )
      .alert(isPresented: $showAlert) {
        Alert(title: Text("Error"),
              message: Text(alertMessage ?? ""),
              dismissButton: .default(Text("OK")))
      }
      .sheet(isPresented: $showAvatarPicker){
        ImagePicker(sourceType: .photoLibrary) {image in
          let resized = image.resizeImage(CGFloat(200), opaque: true)
          avatar = resized.pngData()
          showAvatarPicker = false
        }
      }
    }
  }
  
  private func handleDelete() {
    if let vehicle = self.vehicle {
      vehicle.removed = true
      do {
        try viewContext.save()
      } catch {
        print(error)
      }
      self.onDismiss()
    }
  }
  
  private func handleDone() throws {
    guard let allowed = Int(allowed) else {
      throw AppError.invalidInput(reason: "Allowed mileage is not a number")
    }
    guard let fee = Float(fee) else {
      throw AppError.invalidInput(reason: "Fee is not a valid number")
    }
    guard name.count > 0 else {
      throw AppError.invalidInput(reason: "Name is empty")
    }
    guard let starting = Int(starting) else {
      throw AppError.invalidInput(reason: "Starting mileage is not a valid number")
    }
    guard let lengthOfLease = Int(lengthOfLease) else {
      throw AppError.invalidInput(reason: "Length of lease is not a valid number")
    }
    guard let avatar = avatar else {
      throw AppError.invalidInput(reason: "Please add a vehicle avatar")
    }
    
    let vehicle = self.vehicle ?? Vehicle(context: viewContext)
    vehicle.allowed = Int64(allowed)
    vehicle.fee = fee
    vehicle.name = name
    vehicle.starting = Int64(starting)
    vehicle.startDate = startDate
    vehicle.lengthOfLease = Int64(lengthOfLease)
    vehicle.avatar = avatar
    vehicle.lengthUnit = lengthUnit.rawValue
    vehicle.currency = currency
    vehicle.removed = false
    
    do {
      try viewContext.save()
    } catch {
      throw AppError.failedContextSave
    }
    
    self.onDismiss()
  }
}
