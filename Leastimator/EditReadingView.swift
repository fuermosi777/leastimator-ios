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
            .font(.inter(17, weight: .bold))
          
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
                .font(.inter(11, weight: .bold))
                .foregroundColor(.subText)
                .tracking(1.5)
              
              VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                  Text(formattedReading)
                    .font(.jetBrainsMono(48, weight: .medium))
                    .contentTransition(.numericText())
                  
                  Text(vehicle.lengthUnit == LengthUnit.Metric.rawValue ? "km" : "mi")
                    .font(.inter(18))
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
            
            // Date Section
            VStack(alignment: .leading, spacing: 8) {
              Text("DATE")
                .font(.inter(11, weight: .bold))
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
            
            if reading != nil {
              Button(action: handleDelete) {
                HStack {
                  Image(systemName: "trash")
                  Text("Delete Reading")
                }
                .font(.inter(15, weight: .semibold))
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
          Text("Save Reading")
            .font(.inter(16, weight: .bold))
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
      }
    }
    .task {
      // If found last reading, use its value as default placeholder so that user can easily scroll to desired reading.
      if reading == nil {
        self.readingValue = String(self.readings.last?.value ?? self.vehicle.starting)
      }
    }
  }
  
  private func handleDelete() {
    if let reading = self.reading {
      viewContext.delete(reading)
      do {
        try viewContext.save()
        viewContext.refresh(vehicle, mergeChanges: true)
        vehicle.objectWillChange.send()
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
      viewContext.refresh(vehicle, mergeChanges: true)
      vehicle.objectWillChange.send()
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      throw AppError.failedContextSave
    }
    
    dismiss()
  }
}
