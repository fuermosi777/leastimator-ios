//
//  Persistence.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import CoreData
import Foundation
import CloudKit

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
    PersistenceController.migrateToAppGroupIfNeeded()
    
    container = NSPersistentCloudKitContainer(name: "Leastimator")
    
    // New App Group store location.
    let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.im.liuhao.leastimator")!.appendingPathComponent("Leastimator.sqlite")
    
    let storeDescription = NSPersistentStoreDescription(url: storeURL)
    
    // Always enable history tracking to support potential CloudKit sync and Widget access.
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

    let icloudSyncEnabledKey = "iCloudSyncEnabled"
    // If the setting hasn't been set yet, determine default based on iCloud status.
    if UserDefaults.standard.object(forKey: icloudSyncEnabledKey) == nil {
      let semaphore = DispatchSemaphore(value: 0)
      var status = false
      Task {
        status = await ICloudManager.shared.checkICloudStatus()
        semaphore.signal()
      }
      _ = semaphore.wait(timeout: .now() + 1.5) // Wait briefly for iCloud check
      UserDefaults.standard.set(status, forKey: icloudSyncEnabledKey)
    }

    if UserDefaults.standard.bool(forKey: icloudSyncEnabledKey) {
      storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.im.liuhao.leastimator")
    }
    
    container.persistentStoreDescriptions = [storeDescription]
    
    container.loadPersistentStores(completionHandler: { [unowned container] (storeDescription, error) in
      if let error = error as NSError? {
        // In a real app, you might want to handle this more gracefully than fatalError.
        print("Unresolved error \(error), \(error.userInfo)")
      }
    })
    
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    
    // Observe sync events to track last sync time
    NotificationCenter.default.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: container, queue: .main) { notification in
      guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { return }
      if event.succeeded {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastSyncTime")
      }
    }
  }

  private static func migrateToAppGroupIfNeeded() {
    let fileManager = FileManager.default
    let oldStoreURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Leastimator.sqlite")
    let newStoreURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.im.liuhao.leastimator")!.appendingPathComponent("Leastimator.sqlite")
    
    // If old store exists and new store doesn't, migrate it.
    guard fileManager.fileExists(atPath: oldStoreURL.path) else { return }
    guard !fileManager.fileExists(atPath: newStoreURL.path) else { return }
    
    do {
      let appGroupDirectory = newStoreURL.deletingLastPathComponent()
      if !fileManager.fileExists(atPath: appGroupDirectory.path) {
        try fileManager.createDirectory(at: appGroupDirectory, withIntermediateDirectories: true, attributes: nil)
      }
      
      try fileManager.moveItem(at: oldStoreURL, to: newStoreURL)
      
      // Move auxiliary files
      let shmOldURL = oldStoreURL.appendingPathExtension("sqlite-shm")
      let shmNewURL = newStoreURL.appendingPathExtension("sqlite-shm")
      if fileManager.fileExists(atPath: shmOldURL.path) {
        try fileManager.moveItem(at: shmOldURL, to: shmNewURL)
      }
      
      let walOldURL = oldStoreURL.appendingPathExtension("sqlite-wal")
      let walNewURL = newStoreURL.appendingPathExtension("sqlite-wal")
      if fileManager.fileExists(atPath: walOldURL.path) {
        try fileManager.moveItem(at: walOldURL, to: walNewURL)
      }
      
      print("Successfully migrated database to App Group")
    } catch {
      print("Failed to migrate database: \(error)")
    }
  }
}
