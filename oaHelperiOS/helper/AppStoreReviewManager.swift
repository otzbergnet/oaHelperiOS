//
//  AppStoreReviewManager.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 04.06.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import StoreKit


enum AppStoreReviewManager {
    
    static func requestReviewIfAppropriate() {
        
        let defaults = UserDefaults.standard
        let settings = SettingsBundleHelper()
        let bundle = Bundle.main
        
        let bundleVersionKey = kCFBundleVersionKey as String
        let currentVersion = bundle.object(forInfoDictionaryKey: bundleVersionKey) as? String
        let lastVersion = defaults.string(forKey: "lastReviewRequestAppVersion")
        
        guard lastVersion == nil || lastVersion != currentVersion else {
            return
        }
        
        let oaFound =  settings.getOACount(key: "oa_found")
        let corePdf = settings.getOACount(key: "core_pdf")
        let oaSearch = settings.getOACount(key: "oa_search")
        
        if(oaFound > 25 || corePdf > 10 || oaSearch > 25){
            SKStoreReviewController.requestReview()
            defaults.set(currentVersion, forKey: "lastReviewRequestAppVersion")
        }
        
    }
}


