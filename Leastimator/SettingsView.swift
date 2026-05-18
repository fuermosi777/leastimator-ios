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
  @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
  @AppStorage("lastSyncTime") private var lastSyncTime: Double = 0
  
  @State private var showingRestartAlert = false
  @State private var showingICloudIneligibleAlert = false
  
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
                .tag(index)
            }
          } label: {
            Label {
              Text("Vehicle in widget")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "app.badge")
                .foregroundColor(.subText)
            }
          }
          .onChange(of: selectedVehicleOnWidgetIndex, perform: handleSelectVehicleOnWidgetChange)
        } header: {
          Text("Widget")
        } footer: {
          Text("Choose which vehicle to present in the main screen widget.")
        }
      }
      
      Section {
        Toggle(isOn: $periodicRemindersEnabled) {
          Label {
            Text("Periodic Reminders")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "bell.fill")
              .foregroundColor(.subText)
          }
        }
        if periodicRemindersEnabled {
          Picker(selection: $reminderFrequency) {
            Text("Daily").tag("daily")
            Text("Weekly").tag("weekly")
            Text("Monthly").tag("monthly")
          } label: {
            Label {
              Text("Frequency")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "calendar")
                .foregroundColor(.subText)
            }
          }
          DatePicker(selection: reminderTimeDate, displayedComponents: .hourAndMinute) {
            Label {
              Text("Reminder Time")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "clock")
                .foregroundColor(.subText)
            }
          }
        }
      } header: {
        Text("Periodic Reminders")
      } footer: {
        Text("Get reminded to update your mileage on a schedule.")
      }
      .onChange(of: periodicRemindersEnabled) { _ in updatePeriodicNotification() }
      .onChange(of: reminderFrequency) { _ in updatePeriodicNotification() }
      .onChange(of: reminderTime) { _ in updatePeriodicNotification() }
      
      Section {
        Toggle(isOn: $connectionRemindersEnabled) {
          Label {
            Text("Driving Reminders")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "car.fill")
              .foregroundColor(.subText)
          }
        }
        if connectionRemindersEnabled {
          Stepper(value: $connectionThreshold, in: 1...20) {
            Label {
              Text("Every \(connectionThreshold) connections")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.subText)
            }
          }
        }
      } header: {
        Text("Driving Reminders")
      } footer: {
        Text("Get reminded after connecting to your car (Bluetooth/CarPlay) several times.")
      }
      
      Section {
        Toggle(isOn: $iCloudSyncEnabled) {
          Label {
            Text("iCloud Sync")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "icloud.fill")
              .foregroundColor(.subText)
          }
        }
        .onChange(of: iCloudSyncEnabled) { newValue in
          if newValue {
            Task {
              let available = await ICloudManager.shared.checkICloudStatus()
              if !available {
                iCloudSyncEnabled = false
                showingICloudIneligibleAlert = true
              } else {
                showingRestartAlert = true
              }
            }
          } else {
            showingRestartAlert = true
          }
        }
      } header: {
        Text("Sync")
      } footer: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Keep your data in sync across all your devices using iCloud.")
          if iCloudSyncEnabled && lastSyncTime > 0 {
            Text("Last synced: \(formatSyncDate(Date(timeIntervalSince1970: lastSyncTime)))")
              .foregroundColor(.subText)
          }
        }
      }
      
      Section {
        NavigationLink(destination: DeletedVehiclesView()) {
          Label {
            Text("Deleted Vehicles")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "trash")
              .foregroundColor(.subText)
          }
        }
      } header: {
        Text("Data")
      } footer: {
        Text("View and restore vehicles that were previously deleted.")
      }

      Section {
        NavigationLink(destination: ProProductsView().withErrorHandler().navigationBarTitle("Leastimator Pro", displayMode: .inline)) {
          Label("Leastimator Pro", systemImage: "bolt.fill")
            .foregroundColor(.statusAmber)
        }
      } header: {
        Text("Subscription")
      }
      
      Section {
        Button(action: handleRate) {
          Label {
            Text("Please rate Leastimator")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "star.fill")
              .foregroundColor(.subText)
          }
        }
        
        Link(destination: URL(string: "https://x.com/leastimator")!) {
          Label {
            Text("Contact on X")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "at")
              .foregroundColor(.subText)
          }
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
          HStack {
            Label {
              Text("Version")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "info.circle.fill")
                .foregroundColor(.subText)
            }
            Spacer()
            Text(version)
              .foregroundColor(.subText)
          }
        }
      } header: {
        Text("Support")
      }
      
      Section {
        Link(destination: URL(string: "https://liuhao.im/leastimator/pp")!) {
          Label {
            Text("Privacy Policy")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "lock.shield.fill")
              .foregroundColor(.subText)
          }
        }
        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
          Label {
            Text("Terms of Use")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "doc.text.fill")
              .foregroundColor(.subText)
          }
        }
      } header: {
        Text("Legal")
      }
    }
    .alert(isPresented: $showingRestartAlert) {
      Alert(
        title: Text("Restart Required"),
        message: Text("Please close and restart Leastimator to apply the iCloud sync changes."),
        dismissButton: .default(Text("OK"))
      )
    }
    .alert(isPresented: $showingICloudIneligibleAlert) {
      Alert(
        title: Text("iCloud Not Available"),
        message: Text("Please sign in to iCloud in your device settings to enable sync."),
        dismissButton: .default(Text("OK"))
      )
    }
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

  private func formatSyncDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func updatePeriodicNotification() {
    notificationManager.schedulePeriodicNotification(
      enabled: periodicRemindersEnabled,
      frequency: reminderFrequency,
      time: Date(timeIntervalSince1970: reminderTime)
    )
  }
}
