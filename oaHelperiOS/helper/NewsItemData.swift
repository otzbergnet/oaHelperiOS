//
//  NewsItemData.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 05.05.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit
import CoreData

class NewsItemData: UIViewController {

    let settings = SettingsBundleHelper()
    let helper = HelperClass()
    
    var allNewsItems : [NewsItemObj] = []
    var count = 0
    
    func getNews(forced: Bool, completion: @escaping (Result<News, Error>) -> ()){
        
        if(!forced){
            let lastSynced = settings.getSyncDate(type: "news_sync")
            if(helper.recentSynced(lastDate: lastSynced)){
                return
            }
        }
        
        let highestId = getHighstId()
        var urlString = "https://www.otzberg.net/oahelper/news.php?lang=en&id=\(highestId)"
        
        if let locale = NSLocale.current.languageCode{
            urlString = "https://www.otzberg.net/oahelper/news.php?lang=\(locale)&id=\(highestId)"
        }
        
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, resp, err) in
            
            if let err = err {
                print("error received:", err)
                completion(.failure(err))
                return
            }
            
            do {
                
                let newsItems = try JSONDecoder().decode(News.self, from: data!)
                let testCount = newsItems.item.count
                self.count = 0
                for item in newsItems.item{
                    self.saveNewsItem(newsItem: item, completion: { (Bool) in
                        if(Bool){
                            self.count += 1
                            if(self.count == testCount){
                                completion(.success(newsItems))
                                self.settings.setSyncDate(type: "news_sync")
                            }
                        }
                    })
                }
                
                
            }
            catch let jsonError{
                print("json decode error", jsonError)
                completion(.failure(jsonError))
            }
            
            }.resume()
    }
    
    func getAllNewsItems() -> [NewsItemObj]{
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsItemObj")
        //request.predicate = NSPredicate(format: "del == FALSE")
        let sort = NSSortDescriptor(key: "id", ascending: false)
        request.sortDescriptors = [sort]
        
        if let coreDataStuff = ((try? context.fetch(request) as? [NewsItemObj]) as [NewsItemObj]??) {
            if let coreDataItems = coreDataStuff {
                allNewsItems = coreDataItems
                
                 //uncommented the following can delete all records // keep during dev only
                 /*for item in coreDataItems{
                    context.delete(item)
                    _ = self.saveContext()
                 }*/
 
                
            }
        }
        
        return allNewsItems
    }
    
    func doesNewsItemExist(id: String, update: Bool, delete: Bool) -> Bool{
        if(update && !delete){
            deleteById(id: id)
            return false
        }
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsItemObj")
        request.predicate = NSPredicate(format: "(id == %@)", id)
        if let coreDataStuff = ((try? context.fetch(request) as? [NewsItemObj]) as [NewsItemObj]??) {
            if let coreDataItems = coreDataStuff {
                if(coreDataItems.count > 0){
                    if(delete){
                        for item in coreDataItems{
                            deleteById(id: "\(item.id)")
                        }
                    }
                    return true
                }
            }
        }
        if(delete){
           //If the JSON response tells us to delete and the item is deleted already,
           // pretend it already existed, so we won't try to save
           return true
        }
        else{
           return false
        }
        
    }
    
    func deleteById(id: String){
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsItemObj")
        let sort = NSSortDescriptor(key: "id", ascending: false)
        request.predicate = NSPredicate(format: "(id == %@)", id)
        request.sortDescriptors = [sort]
        request.fetchLimit = 1
        if let coreDataStuff = ((try? context.fetch(request) as? [NewsItemObj]) as [NewsItemObj]??) {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    context.delete(item)
                    _ = self.saveContext()
                }
            }
        }
    }
    
    func getHighstId() -> Int{
        var id : Int16 = 0
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsItemObj")
        let sort = NSSortDescriptor(key: "id", ascending: false)
        request.sortDescriptors = [sort]
        request.fetchLimit = 1
        if let coreDataStuff = ((try? context.fetch(request) as? [NewsItemObj]) as [NewsItemObj]??) {
            if let coreDataItems = coreDataStuff {
                for item in coreDataItems{
                    id = item.id
                }
            }
        }
        
        return Int(id)
    }
    

    
    func saveNewsItem(newsItem: NewsItem, completion: @escaping (Bool) -> ()){
        let newsId = "\(newsItem.id)"
        let update = newsItem.update
        let delete = newsItem.delete
        if(doesNewsItemExist(id: newsId, update: update, delete: delete)){
            completion(true)
            return
        }
        
        let context = self.persistentContainer.viewContext
        let singleNewsItem = NewsItemObj(entity: NewsItemObj.entity(), insertInto: context)
        
        singleNewsItem.id = newsItem.id
        singleNewsItem.date = newsItem.date
        singleNewsItem.title = newsItem.title
        singleNewsItem.body = newsItem.body
        
        if saveContext() {
            completion(true)
        }
        else{
            completion(false)
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
}
