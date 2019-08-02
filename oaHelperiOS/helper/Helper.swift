//
//  Helper.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 05.01.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class HelperClass : UIViewController{
  
    
    func cleanAbstract(txt: String) -> String{
        let toClean = ["&lt;p&gt;", "&lt;em&gt;", "&lt;/p&gt;", "&lt;/em&gt;", "\\ud", "&gt", "<p>", "<it>", "</it>", "&lt;em", "Abstract</p>"]
        var mytxt = txt;
        for token in toClean{
            mytxt = mytxt.replacingOccurrences(of: token, with: "")
        }
        let spaceCharacter = ["\r\n"]
        for space in spaceCharacter{
            mytxt = mytxt.replacingOccurrences(of: space, with: " ")
        }
        let lineBreak = ["\n\n\n", "\n\n", "\n", "</p> ", "</p>", "</p"]
        for abreak in lineBreak{
            mytxt = mytxt.replacingOccurrences(of: abreak, with: "\n")
        }
        
        return mytxt
    }
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    func isSE() -> Bool{
        let smallPhones = ["iPhone8,4","iPhone6,1","iPhone6,2","iPhone5,1","iPhone5,2","iPhone5,3","iPhone5,4","iPhone4,1","iPhone3,1", "iPhone3,2", "iPhone3,3", "iPhone2,1", "iPhone1,2"]
        let model = modelIdentifier()
        if(smallPhones.contains(model)){
            return true
        }
        else{
            return false
        }
    }
    
    func recentSynced(lastDate: String) -> Bool{
        if(lastDate == "0"){
            return false
        }
        var returnValue = false
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let oldDate = dateFormatter.date(from: lastDate) {
            let newDate = Date()
            if let diffInHours = Calendar.current.dateComponents([.hour], from: oldDate, to: newDate).hour {
                if(diffInHours < 2){
                    returnValue = true
                }
            }
        }
        return returnValue
    }
    
    func recentNewsSynced(lastDate: String) -> Bool{
        if(lastDate == "0"){
            return false
        }
        var returnValue = false
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let oldDate = dateFormatter.date(from: lastDate) {
            let newDate = Date()
            if let diffInDays = Calendar.current.dateComponents([.hour], from: oldDate, to: newDate).day {
                if(diffInDays < 5){
                    returnValue = true
                }
            }
        }
        return returnValue
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
    
    
    func updateTabBar(tabBarController: UITabBarController, value: String){
        if let tabItems = tabBarController.tabBar.items{
            let tabItem = tabItems[3]
            tabItem.badgeColor = UIColor(red: 0.102, green: 0.596, blue: 0.988, alpha: 1.00)
            if(value == "0"){
                tabItem.badgeValue = nil
            }
            else{
                tabItem.badgeValue = value
            }
            
        }
    }
    
    func getAPIKeyFromPlist() -> String{
        //we are going to read the api key for coar.ac.uk from apikey.plist
        //this file isn't the github bundle and as such you'll need to create it yourself, it is a simple Object
        // core : String = API Key from core.ac.uk
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "apikey", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
        }
        if let core = nsDictionary?["core"]{
            return "\(core)"
        }
        return ""
    }
    
    func checkCore(search: String, apiKey: String, page: Int, completion: @escaping (Result<Data, Error>) -> ()) {
        
        if let encodedString = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
            
            let jsonUrlString = "https://core.ac.uk/api-v2/articles/search/\(encodedString)?page=\(page)&pageSize=50&metadata=true&fulltext=false&citations=false&similar=false&duplicate=false&urls=true&faithfulMetadata=false&apiKey=\(apiKey)"
            //print(jsonUrlString)
            guard let url = URL(string: jsonUrlString) else {
                return
            }
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                if let error = error{
                    //we got an error, let's tell the user
                    completion(.failure(error))
                    print(error)
                }
                if let data = data {
                    //this worked just fine
                    completion(.success(data))
                }
                else{
                    //another error
                    completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "failed to get data"])))
                    return
                }
                
            }
            task.resume()
        }
        
    }
    
    func createSearch(search: String) -> String{
        //TO DO: need to support AND, OR, NOT
        let andSearch = search.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: " AND ")
        let query = "title:((\(andSearch)) ) OR description:((\(andSearch)) )"
        
        return query
    }

}


