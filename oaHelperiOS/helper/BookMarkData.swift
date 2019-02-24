//
//  BookMarkData.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 24.02.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit
import CoreData

class BookMarkObject {
    var date : Date = Date()
    var doi : String = ""
    var pdf : String = ""
    var synced : Bool = false
    var title : String = ""
    var url : String = ""
}

class NSCustomPersistentContainer: NSPersistentContainer {
    
    override open class func defaultDirectoryURL() -> URL {
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.otzberg.oaHelper")
        //storeURL = storeURL?.appendingPathComponent("Model.sqlite")
        return storeURL!
    }
    
}


class BookMarkData : UIViewController{
    var singleBookMark : [BookMark] = []
    var allBookMarks : [BookMark] = []
    
    func saveBookMark(bookmark: BookMarkObject){
        
        if(doesBookMarkExist(url: bookmark.url)){
            return
        }
        
        let context = self.persistentContainer.viewContext
        let bookMarkItem = BookMark(entity: BookMark.entity(), insertInto: context)
        
        bookMarkItem.date = Date()
        bookMarkItem.doi = bookmark.doi
        bookMarkItem.pdf = bookmark.pdf
        bookMarkItem.synced = false
        bookMarkItem.title = bookmark.title
        bookMarkItem.url = bookmark.url
        
        saveContext()
        
    }
    
    func getAllBookMarks() -> [BookMark]{
        let context = self.persistentContainer.viewContext
        let entityName = String(describing: BookMark.self)
        let request = NSFetchRequest<BookMark>(entityName: entityName)
        if let coreDataStuff = try? context.fetch(request) as [BookMark] {
            let coreDataItems = coreDataStuff
            allBookMarks = coreDataItems
        }
        return allBookMarks
    }
    
    func doesBookMarkExist(url: String) -> Bool{
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "(url == %@)", url)
        if let coreDataStuff = try? context.fetch(request) as? [BookMark] {
            if let coreDataItems = coreDataStuff {
                if(coreDataItems.count > 0){
                    return true
                }
            }
        }
        saveContext()
        return false
    }
    
    func deleteBookmark(url : String){
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "(url == %@)", url)
        if let coreDataStuff = try? context.fetch(request) as? [BookMark] {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    context.delete(item)
                }
            }
        }
        saveContext()
        
    }
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        // Change from NSPersistentContainer to your custom class
        let container = NSCustomPersistentContainer(name: "Model")
        
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
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
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
