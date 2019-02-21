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
    
    func incrementOAFoundCount(){
        var oaCount : Int = self.defaults.integer(forKey: "oa_found")
        oaCount += 1;
        self.defaults.set("\(oaCount)", forKey: "oa_found")
    }

    func incrementOASearchCount(){
        var oaCount : Int = self.defaults.integer(forKey: "oa_search")
        oaCount += 1;
        self.defaults.set("\(oaCount)", forKey: "oa_search")
    }
    
    func getOACount() -> String{
        let oaCount : Int = self.defaults.integer(forKey: "oa_search")
        
        return "\(oaCount)"
    }
    
}
