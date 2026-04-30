//
//  SettingsView.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @AppStorage("showMileageVariance") private var showMileageVariance = true
  @AppStorage("periodicRemindersEnabled") private var periodicRemindersEnabled = false
  @AppStorage("reminderFrequency") private var reminderFrequency = "weekly"
  @AppStorage("reminderTime") private var reminderTime = Date().timeIntervalSince1970
  @AppStorage("connectionRemindersEnabled") private var connectionRemindersEnabled = false
  @AppStorage("connectionThreshold") private var connectionThreshold = 5
  
  @EnvironmentObject private var notificationManager: NotificationManager
  
  var vehicles: FetchedResults<Vehicle>
  
  @State private var selectedVehicleOnWidgetIndex: Int
  
  init(vehicles: FetchedResults<Vehicle>) {
    self.vehicles = vehicles
    
    var initialVehicleOnWidgetIndex = -1
    var initialVehicleOnStartIndex = -1
    if vehicles.count > 0 {
      initialVehicleOnWidgetIndex = 0
      initialVehicleOnStartIndex = 0
    }
    for (index, vehicle) in vehicles.enumerated() {
      if vehicle.showOnWidget {
        initialVehicleOnWidgetIndex = index
      }
    }
    
    _selectedVehicleOnWidgetIndex = State(initialValue: initialVehicleOnWidgetIndex)
  }
  
  var body: some View {
    List {
      if vehicles.count > 0 {
        Section {
          Picker(selection: $selectedVehicleOnWidgetIndex) {
            ForEach(0 ..< self.vehicles.count, id: \.self) { index in
              Text(String(self.vehicles[index].name ?? "--"))
                .font(.inter(15))
                .tag(index)
            }
          } label: {
            Label("Vehicle in widget", systemImage: "app.badge")
              .font(.inter(15))
          }
          .onChange(of: selectedVehicleOnWidgetIndex, perform: handleSelectVehicleOnWidgetChange)
        } header: {
          settingsHeader("Widget")
        } footer: {
          Text("Choose which vehicle to present in the main screen widget.")
            .font(.inter(12))
        }
      }
      
      Section {
        Toggle(isOn: $periodicRemindersEnabled) {
          Label("Periodic Reminders", systemImage: "bell.fill")
            .font(.inter(15))
        }
        if periodicRemindersEnabled {
          Picker(selection: $reminderFrequency) {
            Text("Daily").font(.inter(15)).tag("daily")
            Text("Weekly").font(.inter(15)).tag("weekly")
            Text("Monthly").font(.inter(15)).tag("monthly")
          } label: {
            Label("Frequency", systemImage: "calendar")
              .font(.inter(15))
          }
          DatePicker(selection: reminderTimeDate, displayedComponents: .hourAndMinute) {
            Label("Reminder Time", systemImage: "clock")
              .font(.inter(15))
          }
        }
      } header: {
        settingsHeader("Periodic Reminders")
      } footer: {
        Text("Get reminded to update your mileage on a schedule.")
          .font(.inter(12))
      }
      .onChange(of: periodicRemindersEnabled) { _ in updatePeriodicNotification() }
      .onChange(of: reminderFrequency) { _ in updatePeriodicNotification() }
      .onChange(of: reminderTime) { _ in updatePeriodicNotification() }
      
      Section {
        Toggle(isOn: $connectionRemindersEnabled) {
          Label("Driving Reminders", systemImage: "car.fill")
            .font(.inter(15))
        }
        if connectionRemindersEnabled {
          Stepper(value: $connectionThreshold, in: 1...20) {
            Label("Every \(connectionThreshold) connections", systemImage: "arrow.triangle.2.circlepath")
              .font(.inter(15))
          }
        }
      } header: {
        settingsHeader("Driving Reminders")
      } footer: {
        Text("Get reminded after connecting to your car (Bluetooth/CarPlay) several times.")
          .font(.inter(12))
      }
      
      Section {
        NavigationLink(destination: DeletedVehiclesView()) {
          Label("Deleted Vehicles", systemImage: "trash")
            .font(.inter(15))
        }
      } header: {
        settingsHeader("Data")
      } footer: {
        Text("View and restore vehicles that were previously deleted.")
          .font(.inter(12))
      }

      Section {
        NavigationLink(destination: ProProductsView().withErrorHandler().navigationBarTitle("Leastimator Pro", displayMode: .inline)) {
          Label("Leastimator Pro", systemImage: "bolt.fill")
            .font(.inter(15))
            .foregroundColor(.statusAmber)
        }
      } header: {
        settingsHeader("Subscription")
      }
      
      Section {
        Button(action: handleRate) {
          Label("Please rate Leastimator", systemImage: "star.fill")
            .font(.inter(15))
            .foregroundColor(.mainText)
        }
        
        Link(destination: URL(string: "https://github.com/fuermosi777/leastimator-feedback/issues")!) {
          Label("Feedback", systemImage: "envelope.fill")
            .font(.inter(15))
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
          HStack {
            Label("Version", systemImage: "info.circle.fill")
              .font(.inter(15))
            Spacer()
            Text(version)
              .font(.jetBrainsMono(13))
              .foregroundColor(.subText)
          }
        }
      } header: {
        settingsHeader("Support")
      }
      
      Section {
        Link(destination: URL(string: "https://liuhao.im/leastimator/pp")!) {
          Label("Privacy Policy", systemImage: "lock.shield.fill")
            .font(.inter(15))
        }
        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
          Label("Terms of Use", systemImage: "doc.text.fill")
            .font(.inter(15))
        }
      } header: {
        settingsHeader("Legal")
      }
    }
  }

  private func settingsHeader(_ title: String) -> some View {
    Text(title.uppercased())
      .font(.inter(10, weight: .bold))
      .foregroundColor(.subText)
      .tracking(1.5)
  }
  
  private func handleRate() {
    if let url = URL(string: "itms-apps://apple.com/app/id1228501014") {
      UIApplication.shared.open(url)
    }
  }
  
  private func handleSelectVehicleOnWidgetChange(index: Int) {
    for vehicle in vehicles {
      vehicle.showOnWidget = false
    }
    vehicles[index].showOnWidget = true
    
    do {
      try viewContext.save()
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      print(error)
    }
  }

  private var reminderTimeDate: Binding<Date> {
    Binding(
      get: { Date(timeIntervalSince1970: reminderTime) },
      set: { reminderTime = $0.timeIntervalSince1970 }
    )
  }

  private func updatePeriodicNotification() {
    notificationManager.schedulePeriodicNotification(
      enabled: periodicRemindersEnabled,
      frequency: reminderFrequency,
      time: Date(timeIntervalSince1970: reminderTime)
    )
  }
}
