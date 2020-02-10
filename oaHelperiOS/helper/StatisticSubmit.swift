//
//  StatisticSubmit.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 22.02.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation
import UIKit

class StatisticSubmit {
    
    var uid : String
    let settings = SettingsBundleHelper()
    
    init(){
        self.uid = UIDevice.current.identifierForVendor?.uuidString ?? "_"
    }
    
    func submitStats(){
        
        let submit = self.settings.getSettingsValue(key: "share_stats")
        let stringDate = self.getDate()
        let lastDate = self.settings.getShareDate()
        
        if(submit == false){
            print("statistics submit is false")
            return
        }
        
        if(recentUpdate(lastDate: lastDate)){
            //print("recently updatd statistics")
            return
        }
        
        let oa_found = replaceZeroWithUndersore(value: self.settings.getOACount(key: "oa_found"))
        let oa_search = replaceZeroWithUndersore(value: self.settings.getOACount(key: "oa_search"))
        let core_pdf = replaceZeroWithUndersore(value: self.settings.getOACount(key: "core_pdf"))
        let bookmark_count = replaceZeroWithUndersore(value: self.settings.getOACount(key: "bookmark_count"))
        let recom_count = replaceZeroWithUndersore(value: self.settings.getOACount(key: "recommendation_count"))
        let recom_view = replaceZeroWithUndersore(value: self.settings.getOACount(key: "recommendation_view"))
        
        if(oa_found == "_" && oa_search == "_" && core_pdf == "_" && bookmark_count == "_"){
            print("nothing to share")
            return
        }
        
        
        let urlString = "https://www.oahelper.org/stat.php?oa_search=\(oa_search)&oa_found=\(oa_found)&core_pdf=\(core_pdf)&bookmark_count=\(bookmark_count)&recom_count=\(recom_count)&recom_view=\(recom_view)&uid=\(self.uid)"
        guard let url = URL(string: urlString) else {
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                    print(error)
            }
            if let data = data {
                    do{
                        let myData = try JSONDecoder().decode(Status.self, from: data)
                        if myData.status == 200 {
                            //print("success")
                            self.settings.setDate(date : stringDate)
                        }
                        else{
                            print("another code received \(myData.status)")
                        }
                    }
                    catch let jsonError{
                        print("\(jsonError)")
                    }
            }
            else{
                print("data error")
                return
            }
        }
        task.resume()
    }
    
    func getDate() -> String{
        
        let currentDate = Date();
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let newDate = formatter.string(from: currentDate)
        
        return newDate

    }
    
    func replaceZeroWithUndersore(value : Int) -> String {
        var returnValue = ""
        if(value == 0){
            returnValue = "_"
        }
        else{
            returnValue = "\(value)"
        }
        return returnValue
    }
    
    func recentUpdate(lastDate: String) -> Bool{
        if(lastDate == "0"){
            return false
        }
        var returnValue = false
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let oldDate = dateFormatter.date(from: lastDate) {
            let newDate = Date()
            if let diffInDays = Calendar.current.dateComponents([.day], from: oldDate, to: newDate).day {
                if(diffInDays < 31){
                    returnValue = true
                }
            }
        }
        return returnValue
    }
}

struct Status : Decodable {
    let status : Int
}
