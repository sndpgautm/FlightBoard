//
//  PersistenceService.swift
//  FlightBoard
//
//  Created by iosdev on 06/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//

import Foundation
import CoreData

class PersistenceService {
    // MARK: - Core Data stack
    
    private init() {}
    
    
    static var context: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    //Creates a child managedObjectContext on  privateQueue to load the airport data faster which does not disturbs the mainQueue used for updating changes in UI data
    //Saves the object instances created by childManagedObjectContext only if the context.save() method is called on both child and parent managed object context simultaneoulsy
    static var childManagedObjectContext: NSManagedObjectContext = {
        // Initialize Managed Object Context
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        // Configure Managed Object Context
        moc.parent = PersistenceService.persistentContainer.viewContext
        return moc
    }()
    
    
    
    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "FlightBoard")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    static func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            //Context is on main queue so performs the block synchronously and waits til its done
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            
        }
    }
    
}
