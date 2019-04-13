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
    let settings = SettingsBundleHelper()
    
    var singleBookMark : [BookMark] = []
    var allBookMarks : [BookMark] = []
    
    var changed = 0
    
    
    func saveBookMark(bookmark: BookMarkObject, isFromCloud: Bool = false, completion: @escaping (Bool) -> ()){
        if(doesBookMarkExist(url: bookmark.url)){
            completion(true)
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
        bookMarkItem.id = ("\(bookmark.url)").md5Value
        
        if saveContext() && !isFromCloud && self.settings.getSettingsValue(key: "bookmarks_icloud"){
            self.dataSync.saveBookmark(bookMark: bookMarkItem){ (testValue) in
                if testValue {
                    bookMarkItem.synced = true
                    completion(true)
                    _ = self.saveContext()
                }
            }
            
        }
        else{
            completion(true)
        }
        
    }
    
    func getAllBookMarks() -> [BookMark]{
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        //request.predicate = NSPredicate(format: "del == FALSE")
        let sort = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [sort]
        
        if let coreDataStuff = ((try? context.fetch(request) as? [BookMark]) as [BookMark]??) {
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
        if let coreDataStuff = ((try? context.fetch(request) as? [BookMark]) as [BookMark]??) {
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
        if let coreDataStuff = ((try? context.fetch(request) as? [BookMark]) as [BookMark]??) {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    if(!self.settings.getSettingsValue(key: "bookmarks_icloud")){
                        item.del = true
                        _ = self.saveContext()
                    }
                    else{
                        self.dataSync.deleteBookmark(recordName: item.id!){ (testValue) in
                            if testValue {
                               context.delete(item)
                               _ = self.saveContext()
                            }
                            else{
                                item.del = true
                                _ = self.saveContext()
                            }
                        }
                    }

                }
            }
        }
        _ = saveContext()
    }
    
    func syncDeletedBookmarks(){
        if(!self.settings.getSettingsValue(key: "bookmarks_icloud")){
            return
        }
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "(del == %d)", true)
        if let coreDataStuff = ((try? context.fetch(request) as? [BookMark]) as [BookMark]??) {
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
        print("recordId to Delete: \(recordName)")
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMark")
        request.predicate = NSPredicate(format: "(id == %@)", recordName)
        if let coreDataStuff = ((try? context.fetch(request) as? [BookMark]) as [BookMark]??) {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    //print("deleted deleted")
                    context.delete(item)
                    _ = self.saveContext()
                }
            }
        }
        _ = saveContext()
    }
    
    func saveBookMarkByName(recordId: CKRecord.ID, isFromCloud: Bool = true, completion: @escaping (Bool) -> ()){
        if(!self.settings.getSettingsValue(key: "bookmarks_icloud")){
            print("not icloud bookmark")
            completion(true)
            return
        }
        self.dataSync.fetchBookMarksByName(recordId: recordId){ (test) in
            self.saveBookMark(bookmark: test, isFromCloud: isFromCloud){ (success: Bool) in
                //print("success saveBookMark")
                completion(true)
            }
        }
    }
    
    func syncCloudChanges(completion : @escaping (_ message : String) -> ()){
        if(!self.settings.getSettingsValue(key: "bookmarks_icloud")){
            return
        }
        self.dataSync.queryChanges() { (type : String, id : CKRecord.ID?) in
            //print(id)
            if let myId = id {
                if(type == "deleted"){
                    //print("deleted")
                    self.deleteBookmarkByName(recordName: "\(myId.recordName)")
                }
                else if(type == "changed"){
                    //print("changed")
                    self.changed += 1
                    self.saveBookMarkByName(recordId: myId, isFromCloud: true){ (success: Bool) in
                        //print(success)
                        if(success){
                            self.changed -= 1
                            if(self.reallyDone()){
                                completion("done")
                            }
                        }
                    }
                }
                else if(type == "done" && self.reallyDone()){
                    completion("done")
                }
                
            }
            else{
                completion("\(type)")
            }
   
        }
        self.syncDeletedBookmarks()
    }
    
    public func reallyDone() -> Bool{
        if (self.changed == 0){
            return true
        }
        else{
            return false
        }
    }
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSCustomPersistentContainer(name: "Model")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
               //fatalError("Unresolved error \(error), \(error.userInfo)")
                print("Unresolved error \(error), \(error.userInfo)")
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
                //print("coredata save true")
                return true
                
            }
            catch {
                //print("coredata save false1")
                return false
            }
        }
        else{
            //print("coredata save false2")
            return false
        }
    }
    
    public func syncAllBookmarks(completion : @escaping (_ type : String) -> ()){
        let coreBookmarks = getAllBookMarks()
        for cBookmark in coreBookmarks{
            self.dataSync.saveBookmark(bookMark: cBookmark){ (testValue) in
                if testValue {
                    cBookmark.synced = true
                    _ = self.saveContext()
                }
            }
        }
        completion("done")
    }
    
    public func deleteAllBookmarks(completion: @escaping(_ returned: Bool) ->()) {
        let context = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "BookMark", in: context)
        fetchRequest.includesPropertyValues = false
        do {
            let results = try context.fetch(fetchRequest) as! [NSManagedObject]
            for result in results {
                context.delete(result)
            }
            try context.save()
            completion(true)
        } catch {
            completion(false)
            print("fetch error -\(error.localizedDescription)")
        }
    }
   
}

extension String {
    var md5Value: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = self.data(using: .utf8) {
            _ = d.withUnsafeBytes { body -> String in
                CC_MD5(body.baseAddress, CC_LONG(d.count), &digest)
                
                return ""
            }
        }
        
        return (0 ..< length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
}
