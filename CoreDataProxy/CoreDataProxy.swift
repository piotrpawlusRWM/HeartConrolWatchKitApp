//
//  CoreDataProxy.swift
//  Heart Control
//
//  Created by Piotr Pawluś on 11/09/2017.
//  Copyright © 2017 Thomas Paul Mann. All rights reserved.
//

import Foundation
import CoreData


public class CoreDataProxy: NSObject {
    public var sharedAppGroup: NSString = ""

    public class var sharedInstance : CoreDataProxy {
        return CoreDataProxy()
    }
    
    public func sendData(x: Double, y: Double, z: Double, heartRate: Double, date: Date) {
        
        guard let context = self.managedObjectContext else {
            return
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "Watch", in: context) else {
            return
        }

        let newObject = NSManagedObject(entity: entity, insertInto: context)
        newObject.setValue(x, forKey: "x")
        newObject.setValue(y, forKey: "y")
        newObject.setValue(z, forKey: "z")
        newObject.setValue(heartRate, forKey: "heartRate")
        newObject.setValue(date, forKey: "date")
        
        do {
            try context.save()
        } catch {
            print("Error while saving \(error)")
            abort()
        }
    }
    
    public func reciveData() -> (x: Double, y: Double, z: Double, heartRate: Double, date: Date)? {
        
        guard let context = self.managedObjectContext else {
            return nil
        }
        let entity = NSEntityDescription.entity(forEntityName: "Watch", in: context)
        let request: NSFetchRequest<Watch> = Watch.fetchRequest()
        request.entity = entity
        
        do {
            let results = try context.fetch(request)
            
            if let watchObject = results.first, let date = watchObject.date as Date? {
                return (x: watchObject.x, y: watchObject.y, z: watchObject.z, heartRate: watchObject.heartRate, date: date)
            }
            
        } catch {
            print("Fetching error \(error)")
        }
        
        return nil
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let proxyBundle = Bundle(identifier: "org.railwaymen.healthkitdev.coreDataProxy")
        let modelURL = proxyBundle!.url(forResource: "WatchModel", withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.sharedAppGroup as String)?.path
        
        let sqlitePath = String(format: "%@/%@", containerPath!, "WatchModel")
        let url = URL(fileURLWithPath: sqlitePath)
        
        let  model = self.managedObjectModel;
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: model)
        var error: NSError? = nil
        
        var failureReason = "There was an error creating or loading the application's saved data."

        do {
            try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            coordinator = nil
            
            var dict: [String: Any] = [
                NSLocalizedDescriptionKey: "Failed to initialize the application's saved data",
                NSLocalizedFailureReasonErrorKey: failureReason,
                NSUnderlyingErrorKey: error
            ]
            print("Unresolved error \(error)")
            
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func saveContext () {

        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch {
                    print("Unresolved error \(error)")
                    abort()
                }
            }
        }
    }
}
