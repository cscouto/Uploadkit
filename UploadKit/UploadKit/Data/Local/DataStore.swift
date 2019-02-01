//
//  DataStore.swift
//  UploadKit
//
//  Created by COUTO, TIAGO [AG-Contractor/1000] on 2/1/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//

import CoreData

class DataStore {
    private static var persistentContainer: NSPersistentContainer {
        let container = NSPersistentContainer(name: "UploadKit")
        container.loadPersistentStores { (storeDescriptions, error) in
            if let error = error as NSError? {
                 fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }
    
    static func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Swift.Void) {
        persistentContainer.performBackgroundTask { (context) in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.undoManager = nil
            block(context)
        }
    }
}
