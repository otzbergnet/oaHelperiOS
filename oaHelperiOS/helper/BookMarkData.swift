//
//  BookMarkData.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 24.02.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import CommonCrypto

class BookMarkObject {
    var date : Date = Date()
    var doi : String = ""
    var pdf : String = ""
    var synced : Bool = false
    var del : Bool = false          //using del rather than deleted, as deleted got me an error
    var title : String = ""
    var url : String = ""
    var id : String = ""
}

class NSCustomPersistentContainer: NSPersistentContainer {
    
    override open class func defaultDirectoryURL() -> URL {
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.otzberg.oaHelper")
        //storeURL = storeURL?.appendingPathComponent("Model.sqlite")
        return storeURL!
    }
    
}


class BookMarkData : UIViewController{
    
    //helper class
    //var helper = HelperClass()
    var dataSync = DataSync()
    
    var singleBookMark : [BookMark] = []
    var allBookMarks : [BookMark] = []
    
    func saveBookMark(bookmark: BookMarkObject, isFromCloud: Bool = false){
        
        if(doesBookMarkExist(url: bookmark.url)){
            return
        }
        
        let context = self.persistentContainer.viewContext
        let bookMarkItem = BookMark(entity: BookMark.entity(), insertInto: context)
        
        bookMarkItem.date = Date()
        bookMarkItem.doi = bookmark.doi
        bookMarkItem.pdf = bookmark.pdf
        bookMarkItem.synced = isFromCloud
        bookMarkItem.del = false
        bookMarkItem.title = bookmark.title
        bookMarkItem.url = bookmark.url
        bookMarkItem.id = md5("\(bookmark.url)\(String(describing: bookMarkItem.date))")
        
        if saveContext() && !isFromCloud{
            self.dataSync.saveBookmark(bookMark: bookMarkItem){ (testValue) in
                if testValue {
                    bookMarkItem.synced = true
                    _ = self.saveContext()
                }
            }
            
        }
        
    }
    
    func getAllBookMarks() -> [BookMark]{
        //temporary
        self.syncCloudChanges()
        //
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "del == FALSE")
        if let coreDataStuff = try? context.fetch(request) as? [BookMark] {
            if let coreDataItems = coreDataStuff {
               allBookMarks = coreDataItems
            }
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
        _ = saveContext()
        return false
    }
    
    func deleteBookmark(url : String){
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "(url == %@)", url)
        if let coreDataStuff = try? context.fetch(request) as? [BookMark] {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    self.dataSync.deleteBookmark(recordName: item.id!){ (testValue) in
                        if testValue {
                            context.delete(item)
                            _ = self.saveContext()
                        }
                        else{
                            print("delete fail")
                            item.del = true
                            _ = self.saveContext()
                        }
                    }
                    
                }
            }
        }
        _ = saveContext()
    }
    
    func syncDeletedBookmarks(){
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "(del == %d)", true)
        if let coreDataStuff = try? context.fetch(request) as? [BookMark] {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    self.dataSync.deleteBookmark(recordName: item.id!){ (testValue) in
                        if testValue {
                            context.delete(item)
                            _ = self.saveContext()
                        }
                        else{
                            print("delete fail waiting for next time")
                        }
                    }
                }
            }
        }
    }
    
    func deleteBookmarkByName(recordName : String){
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "(id == %@)", recordName)
        if let coreDataStuff = try? context.fetch(request) as? [BookMark] {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    context.delete(item)
                    _ = self.saveContext()
                }
                    
            }
        }
        _ = saveContext()
        
    }
    
    func saveBookMarkByName(recordId: CKRecord.ID, isFromCloud: Bool = true){
        self.dataSync.fetchBookMarksByName(recordId: recordId){ (test) in
            self.saveBookMark(bookmark: test, isFromCloud: isFromCloud)
        }
    }
    
    func syncCloudChanges(){
        self.dataSync.queryChanges() { (type : String, id : CKRecord.ID) in
            if(type == "deleted"){
                self.deleteBookmarkByName(recordName: "\(id.recordName)")
            }
            else if(type == "changed"){
                self.saveBookMarkByName(recordId: id, isFromCloud: true)
            }
        }
        self.syncDeletedBookmarks()
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
    
    func saveContext() -> Bool {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                return true
                
            }
            catch {
                return false
            }
        }
        else{
            return false
        }
    }
    
    public func syncAllBookmarks(){
        let coreBookmarks = getAllBookMarks()
        for cBookmark in coreBookmarks{
            self.dataSync.saveBookmark(bookMark: cBookmark){ (testValue) in
                if testValue {
                    cBookmark.synced = true
                    _ = self.saveContext()
                }
            }
        }
    }

    // MARK: - MD5 function, in combination with CommonCrypto
    
    func md5(_ string: String) -> String? {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = string.data(using: String.Encoding.utf8) {
            _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }
        
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
    
}
