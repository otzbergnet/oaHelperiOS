//
//  DataSync.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 01.03.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit
import CloudKit

class DataSync: UIViewController {

    
    //var bookMark: CKRecord?
    var newBookMark: Bool = true
    var bookMarkList : [BookMark] = []
    
    //support for settings
    var settings = SettingsBundleHelper()
    
    //CloudKit DB & ZONE
    let defaultContainer = CKContainer(identifier: "iCloud.net.otzberg.oaHelper")
    let privateDatabase = CKContainer(identifier: "iCloud.net.otzberg.oaHelper").privateCloudDatabase
    let customZone = CKRecordZone(zoneName: "bookMarkZone")

    public func fetchUserRecordID() {
        
        // Fetch User Record
        self.defaultContainer.fetchUserRecordID { (recordID, error) -> Void in
            if let responseError = error {
                print(responseError)
                
            } else if let userRecordID = recordID {
                DispatchQueue.main.sync {
                    self.fetchUserRecord(recordID: userRecordID)
                }
            }
        }
    }
    
    private func fetchUserRecord(recordID: CKRecord.ID) {
        
        // Fetch User Record
        self.privateDatabase.fetch(withRecordID: recordID) { (record, error) -> Void in
            if let responseError = error {
                print(responseError)
                
            } else if record != nil {
                self.fetchBookMarks()
            }
        }
    }

    private func fetchBookMarks() {
        
        // Initialize Query
        let query = CKQuery(recordType: "Bookmarks", predicate: NSPredicate(value: true))
        
        // Configure Query
        //query.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        
        // Perform Query
        self.privateDatabase.perform(query, inZoneWith: self.customZone.zoneID) { (records, error) in
            if let responseError = error{
                print(responseError.localizedDescription as Any)
            }
            else {
                records?.forEach({ (record) in
                    
                    guard error == nil else{
                        print(error?.localizedDescription as Any)
                        return
                    }
                    
                    print(record.value(forKey: "url") ?? "")
                })
            }
            
            
        }
    }
    
    func fetchBookMarksByName(recordId: CKRecord.ID, completion: @escaping (BookMarkObject) ->()) {
        
        self.privateDatabase.fetch(withRecordID: recordId){ (record, error) in
            if let responseError = error{
                print(responseError.localizedDescription as Any)
            }
            else {
                if let record = record {
                    let bookMark = BookMarkObject()
                    bookMark.id = record.value(forKey: "id") as? String ?? ""
                    bookMark.date = record.value(forKey: "date") as? Date ?? Date()
                    bookMark.doi = record.value(forKey: "doi") as? String ?? ""
                    bookMark.url = record.value(forKey: "url") as? String ?? ""
                    bookMark.pdf = record.value(forKey: "pdf") as? String ?? ""
                    bookMark.synced = true
                    bookMark.title = record.value(forKey: "title") as? String ?? ""
                    completion(bookMark)
                }

            }
        }
    }
    
    public func saveBookmark(bookMark : BookMark, isFromCloud : Bool = false, completion: @escaping (Bool) -> ()){
       
        if(bookMark.synced){
            completion(true)
            return
        }
        
        let url = bookMark.url! as __CKRecordObjCValue
        let pdf = bookMark.pdf! as __CKRecordObjCValue
        let title = bookMark.title! as __CKRecordObjCValue
        let doi = bookMark.doi! as __CKRecordObjCValue
        let date = bookMark.date!  as __CKRecordObjCValue
        let id = bookMark.id! as __CKRecordObjCValue
        let recordName = bookMark.id!
        
        
        let bookMark = CKRecord(recordType: "Bookmarks", recordID: CKRecord.ID(recordName: recordName, zoneID: self.customZone.zoneID))
        
        // Configure Record
        bookMark.setObject(url , forKey: "url")
        bookMark.setObject(pdf , forKey: "pdf")
        bookMark.setObject(doi , forKey: "doi")
        bookMark.setObject(title, forKey: "title")
        bookMark.setObject(date , forKey: "date")
        bookMark.setObject(id, forKey: "id")
        
        // Save Record
        self.privateDatabase.save(bookMark) { (record, error) -> Void in
            DispatchQueue.main.sync {
                // Process Response
                if self.processResponse(record: record, error: error as? CKError){
                    //worked - need to set sync = true on coreData
                    completion(true)
                }
                else{
                    if let error = error as? CKError{
                        if(error.errorCode == 14){
                            completion(true)
                        }
                        else{
                            completion(false)
                        }
                    }
                    else{
                        completion(false)
                    }
                    
                }
                
            }
            
        }
    }
    
    public func deleteBookmark(recordName : String, completion: @escaping (Bool) -> ()){
        //print("recordName: \(recordName)")
        self.privateDatabase.delete(withRecordID: CKRecord.ID(recordName: recordName, zoneID: self.customZone.zoneID)) { (recordId, error) in
            if recordId != nil{
                completion(true)
            }
            if error != nil{
                completion(false)
            }
        }
        
    }
    
    // MARK: Helper Methods
    private func processResponse(record: CKRecord?, error: CKError?) -> Bool {
        var message = ""
        
        if let error = error {
            message = "We were not able to save your bookmark - error: \(error.errorCode)."
            
        }
        else if record == nil {
            message = "We were not able to save your bookmark."
        }
        
        if message.isEmpty {
            return true
        }
        else {
            print(message)
            return false
        }
    }

    func queryChanges(completion : @escaping (_ type : String, _ id : CKRecord.ID?) -> ()){
        
        let zoneId = self.customZone.zoneID
        
        //keep changeToken in User Defaults
        
        //ensure we use the correct user defaults
        //move this to settingsbundlehelper && find a way that this doesn't sync
        var changeToken : CKServerChangeToken? = nil
        let myStoredChangeToken = self.settings.getChangeToken()
        if let myChangeToken: CKServerChangeToken = myStoredChangeToken as? CKServerChangeToken{
           changeToken = myChangeToken
        }
        else{
           changeToken = nil
        }
        
        // setup options
        //changeToken = nil
        
        let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        options.previousServerChangeToken = changeToken
        
        // define operation
        // we are going to fetchAll Changes
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneId], configurationsByRecordZoneID: [zoneId : options])
        operation.fetchAllChanges = true
        
        //callbacks for operation
        
        operation.recordChangedBlock = {(record) in
            completion("changed", record.recordID)
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            //if you have a lot of changes, you might get a new token
            //extremely unlikely for this project
            guard let changeToken = changeToken else {
                return
            }
            self.settings.setChangeTokenData(changeToken: changeToken)
        }
        operation.recordWithIDWasDeletedBlock = { recordId, recordType in
            completion("deleted", recordId)
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            //potentially problematic
            guard error == nil else {
                var errorType = "generalError"
                if let ckerror = error as? CKError {
                    if ckerror.code == CKError.requestRateLimited {
                        errorType = "requestRateLimit"
                    }
                    else if ckerror.code == CKError.zoneBusy {
                        errorType = "zoneBusy"
                    }
                    else if ckerror.code == CKError.limitExceeded {
                        errorType = "limitExceeded"
                    }
                    else if ckerror.code == CKError.notAuthenticated {
                        errorType = "notAuthenticated"
                    }
                    else if ckerror.code == CKError.networkFailure {
                        errorType = "networkFailure"
                    }
                    else if ckerror.code == CKError.networkUnavailable {
                        errorType = "networkUnavailable"
                    }
                    else if ckerror.code == CKError.quotaExceeded {
                        errorType = "quotaExceeded"
                    }
                    else if ckerror.code == CKError.partialFailure {
                        errorType = "partialFailure"
                    }
                    else if (ckerror.code == CKError.internalError || ckerror.code == CKError.serviceUnavailable) {
                        errorType = "serviceUnavailable"
                    }
                }
    
                let myCompletionReturn = "\(errorType)"
                completion(myCompletionReturn, nil)
                return
   
            }
            
        }
        operation.recordZoneFetchCompletionBlock = {zoneID, changeToken, data, more, error in
            //at end of operation, unless there was an error, we should get a new token
            //by returning early, we could "replay" this operation next time
            guard error == nil else {
                print("error in changeToken 2: \(String(describing: error.debugDescription) )")
                return
            }
            guard let changeToken = changeToken else {
                return
            }
            self.settings.setChangeTokenData(changeToken : changeToken)
            completion("done", CKRecord.ID())
        }

        self.privateDatabase.add(operation)

    }
    
   
    
}
