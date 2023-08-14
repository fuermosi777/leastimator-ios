//
//  LeastimatorApp.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import SwiftUI
import SwiftRater
import GoogleMobileAds

@main
struct LeastimatorApp: App {
  let persistenceController = PersistenceController.shared
  
  @Environment(\.scenePhase) var phase
  
  @StateObject
  private var purchaseManager = PurchaseManager()
  
  @StateObject
  private var notificationManger = NotificationManager()
  
  init() {
    // Use this if NavigationBarTitle is with Large Font
    UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.title]
    // Use this if NavigationBarTitle is with displayMode = .inline
    UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.title]
    
    
    // Set up rater.
    SwiftRater.daysUntilPrompt = 20
    SwiftRater.usesUntilPrompt = 20
    SwiftRater.showLaterButton = true
    SwiftRater.daysBeforeReminding = 5
    // To use this, need to use SwiftRater.incrementSignificantUsageCount()
    // SwiftRater.significantUsesUntilPrompt = 3
    SwiftRater.debugMode = false
    SwiftRater.appLaunched()
    
    // Start logger
    Logger.shared.appStart()
  }
  
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup {
      ContentView()
        .preferredColorScheme(.dark)
        .withErrorHandler()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
      // For localization debug.
//              .environment(\.locale, .init(identifier: "de"))
        .environmentObject(purchaseManager)
        .environmentObject(notificationManger)
      //        .onOpenURL { url in
      //          // Handle deep links.
      //          guard let deepLinkAction = url.deepLinkIdentifier else {
      //            return
      //          }
      //          switch deepLinkAction {
      //          case .addReading:
      //            sheetStore.activeSheet = .addReading
      //          }
      //        }
        .task {
          await purchaseManager.updatePurchasedProducts()
        }
    }.onChange(of: phase) { (newPhase) in
      switch newPhase {
        case .active :
          guard let name = shortcutItemToProcess?.type else {
            return
          }
          // Defined in Info.plist
          if name == "AddReadingAction" {
//            sheetStore.activeSheet = .addReading
          }
        case .inactive, .background:
          return
        @unknown default:
          return
      }
    }
  }
}

// For quick actions.
var shortcutItemToProcess: UIApplicationShortcutItem?

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    if let shortcutItem = options.shortcutItem {
      shortcutItemToProcess = shortcutItem
    }
    
    let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
    sceneConfiguration.delegateClass = CustomSceneDelegate.self
    
    // Initialize Google AdMobs.
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    
    return sceneConfiguration
  }
}

class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
  func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    shortcutItemToProcess = shortcutItem
  }
}
