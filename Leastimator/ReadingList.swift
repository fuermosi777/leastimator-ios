//
//  ReadingList.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct ReadingList: View {
  @Environment(\.dismiss) private var dismiss
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
      ZStack {
        Color.mainBg.ignoresSafeArea()
        
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            if readings.count == 0 {
              Text("You haven't added any readings yet.")
                .font(.inter(14))
                .foregroundColor(.subText)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
              VStack(spacing: 0) {
                ForEach(Array(readings.enumerated()), id: \.element.id) { index, rd in
                  let nextIdx = index + 1
                  let prev = nextIdx < readings.count ? readings[nextIdx] : nil
                  
                  Button(action: {
                    selectedReading = rd
                    showEditReadingSheet = true
                  }) {
                    ReadingRowView(reading: rd, previousReading: prev, unit: lengthUnit.shortFor)
                      .contentShape(Rectangle())
                  }
                  .buttonStyle(.plain)
                  
                  if index < readings.count - 1 {
                    Divider()
                      .background(Color.mainText.opacity(0.05))
                  }
                }
              }
              .padding(.horizontal, 24)
              .background(Color.subBg.opacity(0.3))
              .cornerRadius(24)
              .overlay(
                RoundedRectangle(cornerRadius: 24)
                  .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
              )
              .padding(.horizontal, 20)
              .padding(.top, 16)
            }
          }
          .padding(.bottom, 40)
        }
      }
      .navigationTitle("Odometer History")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $showEditReadingSheet) {
        EditReadingView(vehicle: vehicle,
                        reading: selectedReading)
        .environment(\.managedObjectContext, viewContext)
        .withErrorHandler()
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button { dismiss() } label: {
            Image(systemName: "xmark")
              .foregroundColor(.mainText)
          }
        }
        ToolbarItem(placement: .primaryAction) {
          Button(action: {
            selectedReading = nil
            showEditReadingSheet = true
          }) {
            Image(systemName: "plus.circle.fill")
              .symbolRenderingMode(.hierarchical)
              .foregroundColor(.accentColor)
              .font(.title3)
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            handleExport()
          } label: {
            Image(systemName: "square.and.arrow.up")
              .foregroundColor(.mainText)
          }
        }
      }
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
