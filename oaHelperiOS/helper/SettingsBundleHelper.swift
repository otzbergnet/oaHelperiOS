//
//  SettingsHelper.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 20.02.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class SettingsBundleHelper {
    var defaults: UserDefaults
    var serverChangeTokenKey : String
    
    init(){
        self.defaults = UserDefaults(suiteName: "group.net.otzberg.oaHelper")!
        
        if let uuid = UIDevice.current.identifierForVendor?.uuidString{
            self.serverChangeTokenKey = "\(uuid)"
        }
        else{
            self.serverChangeTokenKey = "icloudServerToken"
        }
        
        
    }
    
    // oa_found, oa_search, core_pdf
    
    func incrementOACount(key : String){
        var oaCount : Int = self.defaults.integer(forKey: key)
        oaCount += 1;
        self.defaults.set("\(oaCount)", forKey: key)
        self.defaults.synchronize()
    }
    
    func getOACount(key : String) -> Int{
        let oaCount : Int = self.defaults.integer(forKey: key)
        return oaCount
    }
    
    func getSettingsValue(key: String) -> Bool{
        return self.defaults.bool(forKey: key)
    }
    
    func getSettingsStringValue(key: String) -> String{
        if let setting = self.defaults.string(forKey: key){
            return setting
        }
        else{
            return ""
        }
    }
    
    func setSettingsValue(value: Bool, key: String){
        self.defaults.set(value, forKey: key)
        self.defaults.synchronize()
    }
    
    func setSettingsStringValue(value: String, key: String){
        self.defaults.set(value, forKey: key)
        self.defaults.synchronize()
    }
    
    func setStringArray(array : [String], key: String){
        self.defaults.set(array, forKey: key)
        self.defaults.synchronize()
    }
    
    func getStringArray(key: String) -> [String] {
        
        if let stringArray = self.defaults.stringArray(forKey: key) {
            return stringArray
        }
        
        return []
    }
    
    func setDate(date : String){
        self.defaults.set(date, forKey: "share_date")
        self.defaults.synchronize()
    }
    
    func getShareDate() -> String{
        var date = "0"
        if let share_date = self.defaults.string(forKey: "share_date"){
            if share_date != "-"{
                date = share_date
            }
        }
        return date
    }
    
    func setSyncDate(type: String){
        
        let currentDate = Date();
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let newDate = formatter.string(from: currentDate)
        self.defaults.set(newDate, forKey: type)
        self.defaults.synchronize()
        
    }
    
    func getSyncDate(type: String) -> String{
        var date = "0"
        if let share_date = self.defaults.string(forKey: type){
            if share_date != "-"{
                date = share_date
            }
        }
        return date
    }
    
    func setBookMarkCount(bookMarkCount : Int){
        self.defaults.set("\(bookMarkCount)", forKey: "bookmark_count")
        self.defaults.synchronize()
    }
    
    func getChangeToken() -> Any{
        var changeToken : CKServerChangeToken? = nil
        let changeTokenData = self.defaults.data(forKey: self.serverChangeTokenKey)
        let changeTokenTestString = self.defaults.string(forKey: self.serverChangeTokenKey)
        if (changeTokenData != nil && changeTokenTestString != "_"){
            if let unarchivedToken = ((try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData!) as? CKServerChangeToken) as CKServerChangeToken??) {
                changeToken = unarchivedToken
            }
        }
        
        if let myChangeToken = changeToken {
            return myChangeToken
        }
        else{
            //print("server changeToken this was empty")
            return "no" as Any
        }
        
    }
    
    func setChangeTokenData(changeToken : CKServerChangeToken){
        //print("new token")
        //print(changeToken)
        if let changeTokenData =  try? NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false) {
            self.defaults.set(changeTokenData, forKey: self.serverChangeTokenKey)
            self.defaults.synchronize()
        }
        else{
            print("saving tokenupdateblock failed")
        }
        
        //print("checking")
        //print(getChangeToken())
    }
    
    func setEmptyChangeTokenData(){
        self.defaults.set(nil, forKey: self.serverChangeTokenKey)
        self.defaults.synchronize()
    }
    
    func ensureSettingsAreRegistered(){
        if(!getSettingsValue(key: "opencitations_settings")){
            setSettingsValue(value: true, key: "opencitations_settings")
            setSettingsValue(value: true, key: "openCitations")
        }
        if(!getSettingsValue(key: "oab_setting")){
            setSettingsValue(value: true, key: "oab_setting")
            setSettingsValue(value: true, key: "open_access_button")
        }
        if(!getSettingsValue(key: "recommendation_setting")){
            setSettingsValue(value: true, key: "recommendation_setting")
            setSettingsValue(value: true, key: "recommendation")
        }
        if(!getSettingsValue(key: "statistic_setting")){
            setSettingsValue(value: true, key: "statistic_setting")
            setSettingsValue(value: true, key: "share_stats")
        }
    }
}
