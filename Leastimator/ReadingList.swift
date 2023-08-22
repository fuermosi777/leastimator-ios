//
//  ReadingList.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct ReadingList: View {
  @Environment(\.managedObjectContext) private var viewContext
  
  let vehicle: Vehicle
  
  @FetchRequest
  private var readings: FetchedResults<OdoReading>
  
  @State private var selectedReading: OdoReading?
  @State private var showEditReadingSheet = false
  @State private var showExportSheet = false
  @State private var historyDocument: OdometerReadingDocument?
  
  init(vehicle: Vehicle) {
    self.vehicle = vehicle
    
    var predicate: NSPredicate?
    predicate = NSPredicate(format: "vehicle = %@", vehicle)
    self._readings = FetchRequest(entity: OdoReading.entity(),
                                  sortDescriptors: [NSSortDescriptor(keyPath: \OdoReading.date, ascending: false)],
                                  predicate: predicate)
    
  }
  
  var lengthUnit: LengthUnit {
    get {
      if let unit = LengthUnit(rawValue: self.vehicle.lengthUnit) {
        return unit
      } else {
        return .Imperial
      }
    }
  }
  
  var body: some View {
    // Trigger this so that it's not nil.
    // https://stackoverflow.com/questions/66262213/swiftui-sheet-unexpectedly-found-nil-while-unwrapping-an-optional-value
    _ = self.selectedReading
    
    return NavigationStack {
      List {
        if readings.count == 0 {
          Text("You haven't added any readings yet.").foregroundColor(.subText)
        } else {
          ForEach(self.readings) { rd in
            if let date = rd.date {
              Button(action: {
                selectedReading = rd
                showEditReadingSheet = true
              }) {
                HStack {
                  Text("\(rd.value) \(lengthUnit.shortFor)").foregroundColor(.mainText)
                  Spacer()
                  Text("\(date.format())").foregroundColor(.subText)
                }
              }
            }
          }
        }
      }
      .sheet(isPresented: $showEditReadingSheet) {
        EditReadingView(vehicle: vehicle,
                        reading: selectedReading)
        .environment(\.managedObjectContext, viewContext)
        .withErrorHandler()
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: {
            selectedReading = nil
            showEditReadingSheet = true
          }) {
            Label("Add Reading", systemImage: "plus.circle.fill")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            handleExport()
          } label: {
            Label("Export", systemImage: "square.and.arrow.up")
          }
        }
      }
      .navigationTitle("Odometer History")
      .navigationBarTitleDisplayMode(.inline)
      .fileExporter(isPresented: $showExportSheet,
                    document: historyDocument,
                    contentType: .plainText,
                    defaultFilename: "history.csv") { result in
        switch result {
          case .success(let url):
            print("Saved to \(url)")
          case .failure(let error):
            print(error.localizedDescription)
        }
      }
    }
  }
}

extension ReadingList {
  private func handleExport() {
    var csvText = "name,date,mileage\n"
    for reading in readings {
      csvText += "\(reading.vehicle?.name ?? kUnknownVehicleName),\(reading.date?.ISO8601Format() ?? "Unknown date"),\(reading.value)\n"
    }
    
    historyDocument = OdometerReadingDocument(initialText: csvText)
    showExportSheet.toggle()
  }
}
