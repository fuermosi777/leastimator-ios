//
//  EditReadingView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct EditReadingView: View {
  @Environment(\.managedObjectContext) private var viewContext
  
  let vehicle: Vehicle
  let reading: Reading?
  var onDismiss: (_ deleted: Bool) -> Void
  
  @State private var date: Date
  @State private var readingValue: String
  
  @State private var showAlert = false
  @State private var alertMessage: String?
  
  
  init(vehicle: Vehicle, reading: Reading? = nil, onDismiss: @escaping (_ deleted: Bool) -> Void) {
    self.onDismiss = onDismiss
    self.vehicle = vehicle
    self.reading = reading
    _date = State(initialValue: reading?.date ?? Date())
    _readingValue = State(initialValue: reading == nil ? "" : String(reading!.value))
  }
  
  var body: some View {
    NavigationView {
      VStack(spacing: 10.0) {
        Group {
          DatePicker(selection: $date,
                     in: ...Date(),
                     displayedComponents: .date) {
            Text("Reading date")
          }
          Divider()
        }
        
        Group {
          LSTextField(label: "Odometer reading",
                      placeholder: "",
                      keyboardType: .numberPad,
                      value: $readingValue)
        }
        
        if reading != nil {
          Spacer().frame(height: 20)
          Button(action: handleDelete) {
            Image(systemName: "trash").foregroundColor(Color.red)
          }
        }
        
        Spacer()
      }
      .padding(10.0)
      .navigationBarTitle(Text(reading != nil ? "Edit Reading" : "Add Reading"),
                          displayMode: .inline)
      .navigationBarItems(
        leading:
          Button( action: { self.onDismiss(false) }) {
            Image(systemName: "xmark")
          },
        trailing:
          Button("Done") {
            do {
              try self.handleSave()
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
    }
  }
  
  private func handleDelete() {
    if let reading = self.reading {
      viewContext.delete(reading)
      self.onDismiss(true)
    }
  }
  
  private func handleSave() throws {
    guard let value = Int(readingValue) else {
      throw AppError.invalidInput(reason: "Odometer reading is not a valid number")
    }
    guard value >= vehicle.starting else {
      throw AppError.invalidInput(reason: "Odometer reading less than the starting mileage of this vehicle")
    }
    
    let reading = self.reading ?? Reading(context: viewContext)
    reading.date = date
    reading.value = Int64(value)
    
    if self.reading == nil {
      reading.vehicle = vehicle
    }
    
    do {
      try viewContext.save()
    } catch {
      throw AppError.failedContextSave
    }
    
    self.onDismiss(false)
  }
}
