//
//  Persistence.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import CoreData

public extension URL {
  /// Returns a URL for the given app group and database pointing to the sqlite database.
  static func storeURL(for appGroup: String, databaseName: String) -> URL {
    guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
      fatalError("Shared file container could not be created.")
    }
    
    return fileContainer.appendingPathComponent("\(databaseName).sqlite")
  }
}

struct PersistenceController {
  static let shared = PersistenceController()
  
  let container: NSPersistentCloudKitContainer
  
  init() {
    container = NSPersistentCloudKitContainer(name: "Leastimator")
    
    // New App Group store location.
    let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.im.liuhao.leastimator")!.appendingPathComponent("Leastimator.sqlite")
    
    let storeDescription = NSPersistentStoreDescription(url: storeURL)
    storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.im.liuhao.leastimator")
    container.persistentStoreDescriptions = [storeDescription]
    
    container.loadPersistentStores(completionHandler: { [unowned container] (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }
}
