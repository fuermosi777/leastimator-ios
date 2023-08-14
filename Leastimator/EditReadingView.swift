//
//  EditReadingView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI
import WidgetKit

struct EditReadingView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject var errorHandler: ErrorHandler
  
  let vehicle: Vehicle
  // The reading to be edited, if nil, create a new reading.
  let reading: OdoReading?
  
  @State private var date: Date
  @State private var readingValue: String
  
  @FetchRequest
  private var readings: FetchedResults<OdoReading>
  
  
  init(vehicle: Vehicle, reading: OdoReading? = nil) {
    self.vehicle = vehicle
    self.reading = reading
    
    let predicate = NSPredicate(format: "vehicle = %@", vehicle)
    self._readings = FetchRequest(entity: OdoReading.entity(),
                                  sortDescriptors: [NSSortDescriptor(keyPath: \OdoReading.date, ascending: true)],
                                  predicate: predicate)
    
    _date = State(initialValue: reading?.date ?? Date())
    _readingValue = State(initialValue: reading == nil ? "" : String(reading!.value))
  }
  
  var body: some View {
    NavigationStack {
      List {
        Section {
          DatePicker(selection: $date,
                     in: ...Date(),
                     displayedComponents: .date) {
            Text("Reading date")
          }
        }
        
        Section {
          MileagePicker(value: $readingValue)
        } footer: {
          Text("Current odometer reading on dashboard.")
        }
        
        if reading != nil {
          Section {
            Button(action: handleDelete) {
              Label("Delete", systemImage: "trash").foregroundColor(Color.red)
            }
          }
        }
      }
      .navigationBarTitle(Text(reading != nil ? "Edit Reading" : "Add Reading"),
                          displayMode: .inline)
      .navigationBarItems(
        leading:
          Button { dismiss() } label: {
            Image(systemName: "xmark")
          },
        trailing:
          Button("Save") {
            do {
              try self.handleSave()
            } catch {
              self.errorHandler.handle(error)
            }
          }
      )
    }.task {
      // If found last reading, use its value as default placeholder so that user can easily scroll to desired reading.
      self.readingValue = String(self.readings.last?.value ?? self.vehicle.starting)
    }
  }
  
  private func handleDelete() {
    if let reading = self.reading {
      viewContext.delete(reading)
      do {
        try viewContext.save()
        WidgetCenter.shared.reloadAllTimelines()
      } catch {
        self.errorHandler.handle(error)
      }

      dismiss()
    }
  }
  
  private func handleSave() throws {
    guard let value = Int(readingValue) else {
      throw AppError.invalidInput(reason: "Odometer reading is not a valid number")
    }
    guard value >= vehicle.starting else {
      throw AppError.invalidInput(reason: "Odometer reading less than the starting mileage of this vehicle")
    }
    
    let reading = self.reading ?? OdoReading(context: viewContext)
    reading.date = date
    reading.value = Int64(value)
    
    if self.reading == nil {
      reading.vehicle = vehicle
    }
    
    do {
      try viewContext.save()
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      throw AppError.failedContextSave
    }
    
    dismiss()
  }
}
