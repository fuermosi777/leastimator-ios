//
//  LeastimatorApp.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import SwiftUI

@main
struct LeastimatorApp: App {
  let persistenceController = PersistenceController.shared
  
  init() {
    // Set inline navigation bar title to transparent.
    UINavigationBar.appearance().barTintColor = .clear
    UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
    UINavigationBar.appearance().shadowImage = UIImage()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
  }
}
