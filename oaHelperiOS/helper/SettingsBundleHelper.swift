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
    let defaults: UserDefaults
    let serverChangeTokenKey : String
    
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
    }
    
    func getOACount(key : String) -> Int{
        let oaCount : Int = self.defaults.integer(forKey: key)
        return oaCount
    }
    
    func getSettingsValue(key: String) -> Bool{
        let value : Bool = self.defaults.bool(forKey: key)
        return value
    }
    
    func setSettingsValue(value: Bool, key: String){
        self.defaults.set(value, forKey: key)
    }
    
    func setDate(date : String){
        self.defaults.set(date, forKey: "share_date")
    }
    
    func getChangeToken() -> Any{
        var changeToken : CKServerChangeToken? = nil
        let changeTokenData = self.defaults.data(forKey: self.serverChangeTokenKey)
        
        if changeTokenData != nil {
            if let unarchivedToken = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData!) as? CKServerChangeToken {
                changeToken = unarchivedToken
            }
        }
        
        if let myChangeToken = changeToken {
            //print("current Token")
            //print(myChangeToken)
            return myChangeToken
        }
        else{
            return changeToken as Any
        }
        
    }
    
    func setChangeTokenData(changeToken : CKServerChangeToken){
        //print("new token")
        //print(changeToken)
        if let changeTokenData =  try? NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false) {
            self.defaults.set(changeTokenData, forKey: self.serverChangeTokenKey)
        }
        else{
            print("saving tokenupdateblock failed")
        }
        
        //print("checking")
        //print(getChangeToken())
    }
}
