//
//  SettingsHelper.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 20.02.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation

class SettingsBundleHelper {
    let defaults: UserDefaults
    
    init(){
        self.defaults = UserDefaults(suiteName: "group.net.otzberg.oaHelper")!
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
    
    
}
