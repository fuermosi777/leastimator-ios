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
  
  init(vehicle: Vehicle) {
    self.vehicle = vehicle
    
    var predicate: NSPredicate?
    predicate = NSPredicate(format: "vehicle = %@", vehicle)
    self._readings = FetchRequest(entity: OdoReading.entity(),
                                  sortDescriptors: [NSSortDescriptor(keyPath: \OdoReading.date, ascending: true)],
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
    
    return List {
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
                      reading: selectedReading,
                      onDismiss: { showEditReadingSheet = false })
      .environment(\.managedObjectContext, viewContext)
      .withErrorHandler()
    }
    .navigationBarItems(
      trailing:
        Button(action: {
          selectedReading = nil
          showEditReadingSheet = true
        }) {
          Image(systemName: "plus.circle")
        }
    )
    
  }
}
