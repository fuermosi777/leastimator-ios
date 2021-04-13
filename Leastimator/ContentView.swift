//
//  ContentView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import SwiftUI
import CoreData

enum ContentViewSheet: Identifiable {
  case vehicleCreation,
       settings
  var id: Int { hashValue }
}

struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext
  
  @FetchRequest(
    entity: Vehicle.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.name, ascending: true)],
    predicate: NSPredicate(format: "removed == nil OR removed == false"))
  private var vehicles: FetchedResults<Vehicle>
  
  @State private var activeSheet: ContentViewSheet?
  
  var body: some View {
    
    NavigationView {
      ScrollView(showsIndicators: false) {
        if vehicles.count == 0 {
          Button(action: { self.activeSheet = .vehicleCreation }) {
            Label("Add vehicle", systemImage: "plus")
          }
        } else {
          VStack(spacing: 10) {
            ForEach(vehicles) { vehicle in
              NavigationLink(destination: VehiclePresentation(vehicle: vehicle)) {
                VehicleRow(vehicle: vehicle)
              }
              Divider()
            }
            
            Spacer()
          }
        }
      }  // ScrollView
      .padding(10)
      .navigationBarTitle("Leastimator")
      .navigationBarItems(
        leading:
          Button(action: { self.activeSheet = .settings }) {
            Image(systemName: "slider.vertical.3")
          },
        trailing:
          Button(action: { self.activeSheet = .vehicleCreation }) {
            Image(systemName: "plus")
          }
      )
      .sheet(item: $activeSheet) { item in
        switch item {
        case .vehicleCreation:
          EditVehicleView(onDismiss: handleSheetDismiss)
        case .settings:
          SettingsView(onDismiss: handleSheetDismiss)
        }
      }
    }  // NavigationView
  }
  
  private func handleSheetDismiss() {
    activeSheet = nil
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
  }
}
