//
//  ContentView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import SwiftUI
import CoreData
import WidgetKit

struct PlusGrayCircle: View {
  var width: CGFloat = 80.0
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.subBg)
        .frame(width: width, height: width)
      Image(systemName: "plus")
        .resizable()
        .frame(width: width / 2, height: width / 2)
        .foregroundColor(.mainText)
    }
  }
}

struct ContentView: View {
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @Environment(\.managedObjectContext) private var viewContext
  @State private var redirectToSettings = false
  @State private var showAddVehicleSheet = false
  @State private var showEditVehicleSheet: Vehicle?
  @State private var showVehicleHistorySheet: Vehicle?
  @State private var showVehicleReadingHistorySheet = false
  @State private var showProProductSheet = false
  
  
  @State private var selectionVersion = 0

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
  
  private var vehicleToDisplay: Vehicle? {
    let _ = selectionVersion
    if !vehicles.isEmpty {
      let vehicleShouldShow = vehicles.filter { $0.showOnStart }.first
      return vehicleShouldShow ?? vehicles.first
    }
    return nil
  }
  
  private var navigationSubtitle: String? {
    vehicleToDisplay?.leaseSubtitle
  }

  private var currentStatusColor: Color {
    if let vehicle = vehicleToDisplay {
      let info = Compute(vehicle)
      let up = Double(info.normalPredicatedMileage)
      let down = Double(vehicle.allowed + vehicle.starting)
      let progress = down > 0 ? up / down : 1.0
      return Color.statusColor(progress: progress)
    }
    return .accentColor
  }

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(colors: [Color("LessBlack"), Color.black],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
        
        VStack {
          if vehicles.isEmpty {
            VStack(spacing: 28) {
              Spacer()
              
              // Top Car Image with glow
              ZStack {
                Circle()
                  .fill(
                    RadialGradient(
                      gradient: Gradient(colors: [Color.accentColor.opacity(0.15), .clear]),
                      center: .center,
                      startRadius: 0,
                      endRadius: 160
                    )
                  )
                  .frame(width: 320, height: 320)
                
                Image("CarCover")
                  .resizable()
                  .scaledToFit()
                  .frame(width: 280)
              }
              
              // Text Content
              VStack(spacing: 12) {
                Text("Track your first lease")
                  .font(.rounded(28, weight: .bold))
                  .foregroundColor(.mainText)
                  .tracking(-0.5)
                
                Text("Add your vehicle and a few odometer readings. We'll project your end-of-lease mileage and coach you to stay on track.")
                  .font(.rounded(15))
                  .foregroundColor(.subText)
                  .multilineTextAlignment(.center)
                  .lineSpacing(4)
                  .padding(.horizontal, 40)
              }
              
              Spacer()
              
              // Add Vehicle Button
              Button {
                showAddVehicleSheet.toggle()
              } label: {
                HStack(spacing: 8) {
                  Image(systemName: "plus")
                    .fontWeight(.bold)
                  Text("Add a vehicle")
                    .fontWeight(.bold)
                }
                .font(.rounded(16, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accentColor)
                .cornerRadius(28)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 15, y: 5)
              }
              .padding(.horizontal, 24)
              .padding(.bottom, 34)
            }
          } else {
            if let vehicle = vehicleToDisplay {
              VehiclePresentation(vehicle: vehicle)
            }
          }
        }  // VStack
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            VehicleSwitcher(
              vehicles: Array(vehicles),
              selectedVehicle: vehicleToDisplay,
              onSelect: { vehicle in
                if purchaseManager.unlockPro {
                  for v in vehicles {
                    v.showOnStart = (v == vehicle)
                  }
                  try? viewContext.save()
                  selectionVersion += 1
                  WidgetCenter.shared.reloadAllTimelines()
                } else if vehicle != vehicleToDisplay {
                  showProProductSheet.toggle()
                }
              },
              onSettings: { redirectToSettings.toggle() },
              onAddVehicle: { showAddVehicleSheet.toggle() },
              statusColor: currentStatusColor
            )
          }
          if let vehicle = vehicleToDisplay {
            ToolbarItem(placement: .secondaryAction) {
              Button {
                showEditVehicleSheet = vehicle
              } label: {
                Label("Edit Vehicle", systemImage: "slider.horizontal.3")
              }
              
            }
            ToolbarItem(placement: .secondaryAction) {
              Button {
                vehicle.archived.toggle()
                try? viewContext.save()
              } label: {
                Label(vehicle.archived ? "Unarchive" : "Archive",
                      systemImage: vehicle.archived ? "archivebox.fill" : "archivebox")
              }
            }
            ToolbarItem(placement: .secondaryAction) {
              Button {
                showVehicleHistorySheet = vehicle
              } label: {
                Label("Odometer History", systemImage: "calendar.badge.clock")
              }
            }
          }
        }
        .sheet(isPresented: $redirectToSettings) {
          NavigationStack {
            SettingsView(vehicles: vehicles)
              .navigationBarTitle("Settings", displayMode: .inline)
              .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                  Button("Done") { redirectToSettings = false }
                }
              }
          }
        }
        .sheet(isPresented: $showProProductSheet) {
          ProProductsView()
            .withErrorHandler()
            .navigationBarTitle("Leastimator Pro", displayMode: .inline)
        }
        .sheet(isPresented: $showAddVehicleSheet) {
          EditVehicleView()
            .withErrorHandler()
        }
        .sheet(item: $showEditVehicleSheet) {
          EditVehicleView(vehicle: $0)
            .withErrorHandler()
        }
        .sheet(item: $showVehicleHistorySheet) {
          VehicleHistoryView(vehicle: $0)
            .environment(\.managedObjectContext, viewContext)
        }
      }
    }
    // This line is critical to prevent purchase page from popping back.
    // https://developer.apple.com/forums/thread/693137
    .navigationViewStyle(.stack)
  }
}
