//
//  ContentView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import SwiftUI
import CoreData
import RealmSwift
import WidgetKit

struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var sheetStore: SheetStore
  
  @FetchRequest(
    entity: Vehicle.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.name, ascending: true)],
    predicate: NSPredicate(format: "removed == nil OR removed == false"))
  private var vehicles: FetchedResults<Vehicle>
  
  /// Get the vehicle which has showOnWidget turned on, or return the first vehicle in the list.
  private var vehicleOnWidget: Vehicle? {
    get {
      var vehicle: Vehicle?
      for veh in vehicles {
        if veh.showOnWidget {
          vehicle = veh
          break
        }
      }
      if vehicle == nil && vehicles.count > 0 {
        vehicle = vehicles[0]
      }
      return vehicle
    }
  }
  
  var body: some View {
    
    NavigationView {
      ScrollView(showsIndicators: false) {
        if vehicles.count == 0 {
          Button(action: { sheetStore.activeSheet = .vehicleCreation }) {
            ZStack {
              Image("CarOutline")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 300)
                .accentColor(.subText)
                .opacity(0.3)
              Image(systemName: "plus")
                .frame(width: 100, height: 100, alignment: .center)
                .overlay(
                  Circle()
                    .stroke(Color.accentColor, lineWidth: 1)
                )
                .padding()
            }
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
          Button(action: { sheetStore.activeSheet = .settings }) {
            Image(systemName: "slider.vertical.3")
          },
        trailing:
          Button(action: { sheetStore.activeSheet = .vehicleCreation }) {
            Image(systemName: "plus")
          }
      )
      .sheet(item: $sheetStore.activeSheet) { item in
        switch item {
        case .vehicleCreation:
          EditVehicleView(onDismiss: handleSheetDismiss)
        case .settings:
          SettingsView(vehicles: vehicles, onDismiss: handleSheetDismiss)
        case .addReading:
          if let vehicle = vehicleOnWidget {
            EditReadingView(vehicle: vehicle, onDismiss: handleSheetDismiss)
              .environment(\.managedObjectContext, viewContext)
          } else {
            // Fallback message.
            VStack {
              Text("No vehicle is added yet")
                .padding(10.0)
              Button(action: handleSheetDismiss) {
                Label("Add a Vehicle", systemImage: "plus")
              }
            }
          }
        }
      }.onAppear(perform: migrateRealm)
    }  // NavigationView
  }
  
  private func migrateRealm() -> Void {
    let isMigrated = UserDefaults.standard.bool(forKey: "legacy-realm-migration-completed")
    if isMigrated { return }
    
    RealmMigrator.setDefaultConfiguration()
    do {
      let realm = try Realm()
      let carResults: Results<Car> = realm.objects(Car.self)
      
      if carResults.count == 0 {
        print("No legacy cars found. Stop.")
        UserDefaults.standard.setValue(true, forKey: "legacy-realm-migration-completed")
        return
      }
      
      print("Found \(carResults.count) legacy cars. Start migrating.")
      
      for car in carResults {
        let vehicle = Vehicle(context: viewContext)
        vehicle.allowed = Int64(car.milesAllowed)
        vehicle.fee = car.fee
        vehicle.name = car.nickname
        vehicle.starting = Int64(car.startingMiles)
        vehicle.startDate = car.leaseStartDate
        vehicle.lengthOfLease = Int64(car.lengthOfLease)
        vehicle.lengthUnit = LengthUnit.mi.rawValue
        vehicle.currency = Currency.usd.rawValue
        vehicle.removed = false
        
        for legacyReading in car.readings {
          let reading = OdoReading(context: viewContext)
          reading.date = legacyReading.date
          reading.value = Int64(legacyReading.value)
          reading.vehicle = vehicle
        }
        
        do {
          try viewContext.save()
          UserDefaults.standard.setValue(true, forKey: "legacy-realm-migration-completed")
          
          print("Migration completed")
        } catch {
          print("Failed to save context in the legacy Realm migration.")
        }
        WidgetCenter.shared.reloadAllTimelines()
      }
    } catch {
      print(error)
    }
    
  }
  
  private func handleSheetDismiss() {
    sheetStore.activeSheet = nil
  }
}
