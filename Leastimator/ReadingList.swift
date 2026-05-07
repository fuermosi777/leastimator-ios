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
  
  @ObservedObject var vehicle: Vehicle
  
  @FetchRequest
  private var readings: FetchedResults<OdoReading>
  
  @State private var selectedReading: OdoReading?
  @State private var showEditReadingSheet = false
  @State private var showExportSheet = false
  @State private var showImportSheet = false
  @State private var historyDocument: OdometerReadingDocument?
  @State private var importAlertMessage: String?
  @State private var showImportAlert = false
  
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
          Menu {
            Button {
              handleExport()
            } label: {
              Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            Button {
              showImportSheet = true
            } label: {
              Label("Import CSV", systemImage: "square.and.arrow.down")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
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
      .fileImporter(isPresented: $showImportSheet,
                    allowedContentTypes: [.plainText, .commaSeparatedText],
                    allowsMultipleSelection: false) { result in
        switch result {
          case .success(let urls):
            if let url = urls.first {
              handleImport(url: url)
            }
          case .failure(let error):
            importAlertMessage = error.localizedDescription
            showImportAlert = true
        }
      }
      .alert("Import Result", isPresented: $showImportAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(importAlertMessage ?? "")
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
  
  private func handleImport(url: URL) {
    // Gain access to the security-scoped resource
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing { url.stopAccessingSecurityScopedResource() }
    }
    
    guard let csvText = try? String(contentsOf: url, encoding: .utf8) else {
      importAlertMessage = "Could not read the selected file."
      showImportAlert = true
      return
    }
    
    let lines = csvText.components(separatedBy: .newlines).filter { !$0.isEmpty }
    guard lines.count > 1 else {
      importAlertMessage = "The file appears to be empty or has no data rows."
      showImportAlert = true
      return
    }
    
    // Parse header to find column indices
    let header = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
    guard let dateIndex = header.firstIndex(of: "date"),
          let mileageIndex = header.firstIndex(of: "mileage") else {
      importAlertMessage = "CSV must contain 'date' and 'mileage' columns."
      showImportAlert = true
      return
    }
    
    // Build a set of existing (date-day, value) pairs for duplicate detection
    let calendar = Calendar.current
    var existingPairs = Set<String>()
    for rd in readings {
      if let d = rd.date {
        let comps = calendar.dateComponents([.year, .month, .day], from: d)
        let key = "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)-\(rd.value)"
        existingPairs.insert(key)
      }
    }
    
    let isoFormatter = ISO8601DateFormatter()
    var imported = 0
    var skipped = 0
    
    for line in lines.dropFirst() {
      let cols = line.components(separatedBy: ",")
      guard cols.count > max(dateIndex, mileageIndex) else { skipped += 1; continue }
      
      let dateStr = cols[dateIndex].trimmingCharacters(in: .whitespaces)
      let mileageStr = cols[mileageIndex].trimmingCharacters(in: .whitespaces)
      
      guard let date = isoFormatter.date(from: dateStr),
            let mileage = Int64(mileageStr) else { skipped += 1; continue }
      
      let comps = calendar.dateComponents([.year, .month, .day], from: date)
      let key = "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)-\(mileage)"
      
      if existingPairs.contains(key) { skipped += 1; continue }
      existingPairs.insert(key)
      
      let newReading = OdoReading(context: viewContext)
      newReading.date = date
      newReading.value = mileage
      newReading.vehicle = vehicle
      imported += 1
    }
    
    if imported > 0 {
      do {
        try viewContext.save()
        importAlertMessage = "Successfully imported \(imported) reading\(imported == 1 ? "" : "s")" + (skipped > 0 ? ", skipped \(skipped) duplicate\(skipped == 1 ? "" : "s")." : ".")
      } catch {
        viewContext.rollback()
        importAlertMessage = "Failed to save imported readings: \(error.localizedDescription)"
      }
    } else {
      importAlertMessage = "No new readings to import" + (skipped > 0 ? " (\(skipped) duplicate\(skipped == 1 ? "" : "s") skipped)." : ".")
    }
    showImportAlert = true
  }
}
