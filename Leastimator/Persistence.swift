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
  
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    for _ in 0..<10 {
      let newItem = Vehicle(context: viewContext)
    }
    do {
      try viewContext.save()
    } catch {
      // Replace this implementation with code to handle the error appropriately.
      // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    return result
  }()
  
  let container: NSPersistentContainer
  
  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "Leastimator")
    
    let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.im.liuhao.leastimator")!.appendingPathComponent("Leastimator.sqlite")
    
    var defaultURL: URL?
    if let storeDescription = container.persistentStoreDescriptions.first, let url = storeDescription.url {
      defaultURL = FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    if defaultURL == nil {
      container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
    }
    
    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    
    container.loadPersistentStores(completionHandler: { [unowned container] (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
      
      if let url = defaultURL, url.absoluteString != storeURL.absoluteString {
        let coordinator = container.persistentStoreCoordinator
        if let oldStore = coordinator.persistentStore(for: url) {
          do {
            try coordinator.migratePersistentStore(oldStore, to: storeURL, options: nil, withType: NSSQLiteStoreType)
          } catch {
            print(error.localizedDescription)
          }
          
          // delete old store
          let fileCoordinator = NSFileCoordinator(filePresenter: nil)
          fileCoordinator.coordinate(writingItemAt: url, options: .forDeleting, error: nil, byAccessor: { url in
            do {
              try FileManager.default.removeItem(at: url)
            } catch {
              print(error.localizedDescription)
            }
          })
        }
      }
    })
  }
}
