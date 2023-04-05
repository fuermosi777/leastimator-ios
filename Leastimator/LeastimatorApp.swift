//
//  LeastimatorApp.swift
//  Leastimator
//
//  Created by Hao Liu on 4/4/23.
//

import SwiftUI

@main
struct LeastimatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
