//
//  EditReadingView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct EditReadingView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject var errorHandler: ErrorHandler
  
  @ObservedObject var vehicle: Vehicle
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
  
  var extendedInfo: ExtendedVehicleInfo {
    return Compute(vehicle)
  }
  
  var progressPercentage: Float {
    let up = Float(extendedInfo.normalPredicatedMileage)
    let down = Float(vehicle.allowed + vehicle.starting)
    if down > 0 {
      return min(Float(up / down), 1.0)
    }
    return 1.0
  }
  
  private var statusColor: Color {
    Color.statusColor(progress: Double(progressPercentage))
  }

  private var formattedReading: String {
    let value = Int(readingValue) ?? 0
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: value)) ?? "0"
  }

  // The most recent reading that isn't the one being edited
  private var latestOtherReading: OdoReading? {
    readings.last(where: { $0 != reading })
  }

  private var isBelowLatest: Bool {
    guard reading == nil else { return false }
    guard let latest = latestOtherReading, let value = Int(readingValue) else { return false }
    return value < Int(latest.value)
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
          
          Text(reading != nil ? "Edit Reading" : "Add Reading")
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
            // Odometer Section
            VStack(alignment: .leading, spacing: 8) {
              Text("ODOMETER")
                .font(.rounded(11, weight: .bold))
                .foregroundColor(.subText)
                .tracking(1.5)
              
              VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                  Text(formattedReading)
                    .font(.rounded(48, weight: .medium))
                    .contentTransition(.numericText())
                  
                  Text(vehicle.lengthUnit == LengthUnit.Metric.rawValue ? "km" : "mi")
                    .font(.rounded(18))
                    .foregroundColor(.subText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.horizontal, 18)
                
                Divider()
                  .padding(.vertical, 14)
                  .padding(.horizontal, 18)
                
                MileagePicker(value: $readingValue)
                  .padding(.bottom, 8)
              }
              .background(Color.subBg.opacity(0.3))
              .cornerRadius(16)
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
              )
            }
            
            // Warning if below latest reading
            if isBelowLatest, let latest = latestOtherReading {
              HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(.orange)
                Text("Must be at least \(latest.value) \(vehicle.lengthUnit == LengthUnit.Metric.rawValue ? "km" : "mi"), the current latest reading.")
                  .font(.rounded(13))
                  .foregroundColor(.orange)
              }
              .padding(.horizontal, 14)
              .padding(.vertical, 12)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color.orange.opacity(0.1))
              .cornerRadius(12)
            }

            // Date Section
            VStack(alignment: .leading, spacing: 8) {
              Text("DATE")
                .font(.rounded(11, weight: .bold))
                .foregroundColor(.subText)
                .tracking(1.5)
              
              HStack {
                DatePicker("Reading date", selection: $date, in: ...Date(), displayedComponents: .date)
                  .labelsHidden()
                  .tint(statusColor)
                
                Spacer()
                
                Image(systemName: "calendar")
                  .font(.system(size: 18))
                  .foregroundColor(.subText)
              }
              .padding(.horizontal, 18)
              .padding(.vertical, 16)
              .background(Color.subBg.opacity(0.3))
              .cornerRadius(16)
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
              )
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
          Text("Save Reading")
            .font(.rounded(16, weight: .bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isBelowLatest ? Color.gray.opacity(0.4) : statusColor)
            .cornerRadius(28)
            .shadow(color: isBelowLatest ? .clear : statusColor.opacity(0.3), radius: 15, y: 5)
        }
        .disabled(isBelowLatest)
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
        .background(Color.mainBg)
      }
    }
    .task {
      // If found last reading, use its value as default placeholder so that user can easily scroll to desired reading.
      if reading == nil {
        self.readingValue = String(self.readings.last?.value ?? self.vehicle.starting)
      }
    }
  }
  
  private func handleSave() throws {
    guard let value = Int(readingValue) else {
      throw AppError.invalidInput(reason: "Odometer reading is not a valid number")
    }

    try OdoReadingWriter.save(value: value,
                              date: date,
                              vehicle: vehicle,
                              editing: self.reading,
                              in: viewContext)

    dismiss()
  }
}
