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
  
  var onDismiss: () -> Void
  
  @FetchRequest
  private var readings: FetchedResults<Reading>
  
  @State private var showReadingEdition = false
  
  @State private var selectedReading: Reading?
  
  init(vehicle: Vehicle, onDismiss: @escaping () -> Void) {
    self.vehicle = vehicle
    self.onDismiss = onDismiss
    
    var predicate: NSPredicate?
    predicate = NSPredicate(format: "vehicle = %@", vehicle)
    self._readings = FetchRequest(entity: Reading.entity(),
                                  sortDescriptors: [NSSortDescriptor(keyPath: \Reading.date, ascending: true)],
                                  predicate: predicate)
  }
  
  var body: some View {
    NavigationView {
      VStack(spacing: 10.0) {
        if readings.count == 0 {
          Text("You haven't added any readings yet.").foregroundColor(.subText)
        } else {
          ForEach(self.readings) { rd in
            if let date = rd.date, let value = rd.value {
              Button(action: { self.selectedReading = rd }) {
                HStack {
                  Text("\(value) MI").foregroundColor(.mainText)
                  Spacer()
                  Text("\(date.format())").foregroundColor(.subText)
                }
              }
              Divider()
            }
          }
        }
        Spacer()
      }
      .padding(10.0)
      .navigationBarTitle("Reading history", displayMode: .inline)
      .navigationBarItems(
        leading:
          Button(action: { self.onDismiss() }) {
            Image(systemName: "xmark")
          })
      .sheet(item: $selectedReading) { item in
        EditReadingView(vehicle: vehicle,
                        reading: item,
                        onDismiss: handleDismiss)
      }
    }
  }
  
  private func handleDismiss() {
    selectedReading = nil
  }
}
