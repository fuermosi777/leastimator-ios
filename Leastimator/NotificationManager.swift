//
//  NotificationManager.swift
//  Leastimator
//
//  Created by Hao Liu on 3/15/23.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
  @Published
  private(set) var permissionGranted = false
  
  func checkPermissions() {
    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
      DispatchQueue.main.async {
        if settings.authorizationStatus == .notDetermined {
          // Notification permission is yet to be been asked go for it!
          self.requestNotificationPermission()
        } else if settings.authorizationStatus == .denied {
          // Notification permission was denied previously, go to settings & privacy to re-enable the permission
          self.permissionGranted = false
        } else if settings.authorizationStatus == .authorized {
          self.permissionGranted = true
        }
      }
    })
  }
  
  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
      if success {
        self.permissionGranted = true
      } else if let error = error {
        print(error.localizedDescription)
      }
    }
  }
  
}
