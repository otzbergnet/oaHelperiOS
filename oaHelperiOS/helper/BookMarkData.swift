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

class BookMark {
    var date : Date = Date()
    var doi : String = ""
    var pdf : String = ""
    var synced : Bool = false
    var del : Bool = false
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
    
    var singleBookMark : [BookMarkObj] = []
    var allBookMarks : [BookMarkObj] = []
    
    var changed = 0
    
    
    func saveBookMark(bookmark: BookMarkObject, isFromCloud: Bool = false, completion: @escaping (Bool) -> ()){
        if(doesBookMarkExist(url: bookmark.url)){
            completion(true)
            return
        }

        let entity = NSEntityDescription.entity(forEntityName: "BookMarkObj", in: self.persistentContainer.viewContext)
        let item = NSManagedObject(entity: entity!, insertInto: self.persistentContainer.viewContext)
        item.setValue(Date(), forKey: "date")
        item.setValue(bookmark.doi, forKey: "doi")
        item.setValue(bookmark.pdf, forKey: "pdf")
        item.setValue(isFromCloud, forKey: "synced")
        item.setValue(false, forKey: "del")
        item.setValue(bookmark.title, forKey: "title")
        item.setValue(bookmark.url, forKey: "url")
        item.setValue(("\(bookmark.url)").md5Value, forKey: "id")
        
        let bookMarkItem = BookMark()
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
            _ = saveContext()
            completion(true)
        }
            
        }
        
        func getAllBookMarks() -> [BookMarkObj]{
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMarkObj")
            //request.predicate = NSPredicate(format: "del == FALSE")
            let sort = NSSortDescriptor(key: "title", ascending: true)
            request.sortDescriptors = [sort]
            
            if let coreDataStuff = ((try? self.persistentContainer.viewContext.fetch(request) as? [BookMarkObj]) as [BookMarkObj]??) {
                if let coreDataItems = coreDataStuff {
                    allBookMarks = coreDataItems
                }
            }
            _ = saveContext()
            return allBookMarks
        }
        
        func doesBookMarkExist(url: String) -> Bool{
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMarkObj")
            request.predicate = NSPredicate(format: "(url == %@)", url)
            if let coreDataStuff = ((try? self.persistentContainer.viewContext.fetch(request) as? [BookMarkObj]) as [BookMarkObj]??) {
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
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMarkObj")
            request.predicate = NSPredicate(format: "(url == %@)", url)
            if let coreDataStuff = ((try? self.persistentContainer.viewContext.fetch(request) as? [BookMarkObj]) as [BookMarkObj]??) {
                if let coreDataItems = coreDataStuff {
                    for item in coreDataItems{
                        if(!self.settings.getSettingsValue(key: "bookmarks_icloud")){
                            item.del = true
                            _ = self.saveContext()
                        }
                        else{
                            self.dataSync.deleteBookmark(recordName: item.id!){ (testValue) in
                                if testValue {
                                    self.persistentContainer.viewContext.delete(item)
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
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMarkObj")
            request.predicate = NSPredicate(format: "(del == %d)", true)
            if let coreDataStuff = ((try? self.persistentContainer.viewContext.fetch(request) as? [BookMarkObj]) as [BookMarkObj]??) {
                if let coreDataItems = coreDataStuff {
                    for item in coreDataItems{
                        self.dataSync.deleteBookmark(recordName: item.id!){ (testValue) in
                            if testValue {
                                self.persistentContainer.viewContext.delete(item)
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
            //print("recordId to Delete: \(recordName)")
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookMarkObj")
            request.predicate = NSPredicate(format: "(id == %@)", recordName)
            if let coreDataStuff = ((try? self.persistentContainer.viewContext.fetch(request) as? [BookMarkObj]) as [BookMarkObj]??) {
                if let coreDataItems = coreDataStuff {
                    for item in coreDataItems{
                        //print("deleted deleted")
                        self.persistentContainer.viewContext.delete(item)
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
                        self.deleteBookmarkByName(recordName: "\(myId.recordName)")
                    }
                    else if(type == "changed"){
                        self.changed += 1
                        self.saveBookMarkByName(recordId: myId, isFromCloud: true){ (success: Bool) in
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
            do {
                try self.persistentContainer.viewContext.save()
                return true
                
            }
            catch {
                return false
            }
        }
        
        public func syncAllBookmarks(completion : @escaping (_ type : String) -> ()){
            let coreBookmarks = getAllBookMarks()
            for cBookmark in coreBookmarks{
                let myBookMark = BookMark()
                myBookMark.date = cBookmark.date ?? Date()
                myBookMark.doi = cBookmark.doi ?? ""
                myBookMark.pdf = cBookmark.pdf ?? ""
                myBookMark.synced = cBookmark.synced
                myBookMark.del = cBookmark.del
                myBookMark.title = cBookmark.title ?? ""
                myBookMark.url = cBookmark.url ?? ""
                myBookMark.id  = cBookmark.id ?? ("\(String(describing: cBookmark.url))").md5Value
                self.dataSync.saveBookmark(bookMark: myBookMark){ (testValue) in
                    if testValue {
                        cBookmark.synced = true
                        _ = self.saveContext()
                    }
                }
            }
            completion("done")
        }
        
        public func deleteAllBookmarks(completion: @escaping(_ returned: Bool) ->()) {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = NSEntityDescription.entity(forEntityName: "BookMarkObj", in: self.persistentContainer.viewContext)
            fetchRequest.includesPropertyValues = false
            do {
                let results = try self.persistentContainer.viewContext.fetch(fetchRequest) as! [NSManagedObject]
                for result in results {
                    self.persistentContainer.viewContext.delete(result)
                    
                }
                try self.persistentContainer.viewContext.save()
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
