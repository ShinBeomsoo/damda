//
//  PersistenceControler.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init() {
        // Decide model name by environment for store naming only
        let modelName: String = (try? { EnvironmentManager.shared.getCoreDataModelName() }()) ?? "damda"

        // Prefer a merged model from the app bundle to ensure all target-included entities are present
        if let merged = NSManagedObjectModel.mergedModel(from: [Bundle.main]) {
            container = NSPersistentContainer(name: modelName, managedObjectModel: merged)
        } else if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") ??
                    Bundle.main.url(forResource: modelName, withExtension: "mom"),
                  let explicit = NSManagedObjectModel(contentsOf: modelURL) {
            container = NSPersistentContainer(name: modelName, managedObjectModel: explicit)
        } else {
            container = NSPersistentContainer(name: modelName)
        }

        // Enable lightweight migration
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error)")
            }
        }
    }
}
