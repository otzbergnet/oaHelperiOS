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
        let toClean = ["&lt;p&gt;", "&lt;em&gt;", "&lt;/p&gt;", "&lt;/em&gt;", "\\ud", "&gt", "<p>", "<it>", "</it>", "&lt;em", "Abstract</p>", "<i>", "</i>", "<h4>", "</h4>"]
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
    
    func getAPIKeyFromPlist(key: String) -> String{
        //we are going to read the api key for coar.ac.uk from apikey.plist
        //this file isn't the github bundle and as such you'll need to create it yourself, it is a simple Object
        // core : String = API Key from core.ac.uk
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "apikey", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
        }
        if let core = nsDictionary?[key]{
            return "\(core)"
        }
        return ""
    }
    
    
    func checkCore(search: String, apiKey: String, page: Int, completion: @escaping (Result<SearchResult, Error>) -> ()) {
        
        if let encodedString = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
            
            let jsonUrlString = "https://api.core.ac.uk/v3/search/works"
            
            let json: [String: Any] = [
                "q": search,
                "offset": page,
                "limit": 50,
                "exclude": ["fullText"],
                "sort": []
            ]
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            
            guard let url = URL(string: jsonUrlString) else {
                return
            }
            
            //setup POST REQUEST
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            
            let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                if let error = error{
                    //we got an error, let's tell the user
                    completion(.failure(NSError(domain: "", code: 444, userInfo: ["description" : "\(error.localizedDescription)"])))
                    print(error)
                }
                if let data = data {
                    //this worked just fine
                    do{
                        let coreData = try JSONDecoder().decode(Core.self, from: data)
                        if(coreData.totalHits > 0){
                            let totalHits = coreData.totalHits
                            let tmpMaxPage = Double(Double(totalHits) / 50)
                            
                            let searchResults = SearchResult()
                            searchResults.service = "core"
                            searchResults.hitCount = totalHits
                            searchResults.maxPage = Int(tmpMaxPage.rounded(.up))
                            searchResults.page = page
                            searchResults.searchTerm = search
                            let coreRecords = coreData.results
                            for record in coreRecords {
                                searchResults.records.append(self.makeRecordsFromCore(sourceRecord: record))
                            }
                            completion(.success(searchResults))
                        }
                        else{
                            completion(.failure(NSError(domain: "", code: 442, userInfo: ["description" : "no results"])))
                            return
                        }
                        
                    }
                    catch let jsonError{
                        print(jsonError)
                        print("Core json error")
                        completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "json decode error"])))
                        return
                    }
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
    
    func makeRecordsFromCore(sourceRecord: Items) -> SearchResultRecords{
        let record = SearchResultRecords()
        record.title = sourceRecord.title ?? ""
        var authorCount = 0;
        if let authorArray = sourceRecord.authors{
            for author in authorArray {
                if (authorCount < 3) {
                    record.author += "\(author.name); "
                    authorCount += 1
                }
            }
            if(authorArray.count > 3){
                record.author += " et al."
            }
        }
        record.source = "Core"
        record.year = "\(sourceRecord.yearPublished ?? 0)"
        record.abstract = sourceRecord.abstract ?? ""
        
        if let identifiers = sourceRecord.identifiers {
            for ident in identifiers {
                if (ident.type == "CORE_ID") {
                    let recordId = ident.identifier;
                    record.hasFT = false
                    record.linkUrl = "https://core.ac.uk/display/\(recordId)"
                    record.buttonLabel = NSLocalizedString("View Record at core.ac.uk", comment: "button, core.ac.uk document")
                    record.smallButtonLabel = "core.ac.uk"
                    record.buttonColor = "blue"
                }
            }
        }
        
        if let downloadUrl = sourceRecord.downloadUrl{
            if(downloadUrl != ""){
                record.hasFT = true
                record.buttonLabel = NSLocalizedString("Access Full Text", comment: "button, access full text")
                record.smallButtonLabel = "Full Text"
                record.buttonColor = "green"
                record.linkUrl = downloadUrl
            }
        }
        
        return record
        
    }
    
    
    func checkEPMC(search: String, nextCursorMark: String, page: Int, completion: @escaping (Result<SearchResult, Error>) -> ()) {
        if let encodedString = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
            
            let jsonUrlString = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=\(encodedString)+AND+(HAS_FT:Y)&format=json&synonym=yes&pageSize=50&resultType=core&cursorMark=\(nextCursorMark)"
            guard let url = URL(string: jsonUrlString) else {
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                if let error = error{
                    //we got an error, let's tell the user
                    completion(.failure(NSError(domain: "", code: 444, userInfo: ["description" : "\(error.localizedDescription)"])))
                    print(error)
                }
                if let data = data {
                    //this worked just fine
                    do{
                        let epmcData = try JSONDecoder().decode(EPMC.self, from: data)
                        if let totalHits = epmcData.hitCount {
                            if (totalHits > 0) {
                                let tmpMaxPage = Double(Double(totalHits) / 50)
                                let searchResults = SearchResult()
                                searchResults.service = "epmc"
                                searchResults.token = epmcData.nextCursorMark ?? ""
                                searchResults.searchTerm = search
                                searchResults.hitCount = totalHits
                                searchResults.maxPage = Int(tmpMaxPage.rounded(.up))
                                searchResults.page = page
                                if let epmcRecords = epmcData.resultList?.result{
                                    
                                    for record in epmcRecords {
                                        searchResults.records.append(self.makeRecordsFromEPMC(sourceRecord: record))
                                    }
                                    completion(.success(searchResults))
                                }
                                else{
                                    completion(.failure(NSError(domain: "", code: 443, userInfo: ["description" : "failed to get data"])))
                                    return
                                }
                            }
                            else{
                                completion(.failure(NSError(domain: "", code: 442, userInfo: ["description" : "no results"])))
                                return
                            }
                        }
                        else{
                            completion(.failure(NSError(domain: "", code: 442, userInfo: ["description" : "no results"])))
                            return
                        }
                        
                    }
                    catch let jsonError{
                        print(jsonError)
                        completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "json decode error"])))
                        return
                    }
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
    
    func makeRecordsFromEPMC(sourceRecord: EpmcItems) -> SearchResultRecords{
        let record = SearchResultRecords()
        record.title = sourceRecord.title ?? ""
        record.author = sourceRecord.authorString ?? ""
        //record.source = "Core"
        record.year = sourceRecord.pubYear ?? ""
        record.abstract = sourceRecord.abstractText ?? ""
        record.hasFT = true
        var goodLink = false
        if let urlList = sourceRecord.fullTextUrlList?.fullTextUrl {
            for url in urlList {
                if (!goodLink && (url.availabilityCode == "OA" || url.availabilityCode == "Free") && url.documentStyle == "pdf"){
                    record.linkUrl = url.url ?? ""
                    record.buttonLabel = NSLocalizedString("Access Full Text", comment: "button, access full text")
                    record.smallButtonLabel = "PDF"
                    record.buttonColor = "green"
                    goodLink = true
                }
                else if(!goodLink && (url.availabilityCode == "OA" || url.availabilityCode == "Free") && url.documentStyle == "html"){
                    record.linkUrl = url.url ?? ""
                    record.buttonLabel = NSLocalizedString("Access Full Text", comment: "button, access full text")
                    record.smallButtonLabel = "HTML"
                    record.buttonColor = "green"
                }
            }
        }
        if(record.linkUrl == ""){
            record.linkUrl = "https://europepmc.org/article/\(sourceRecord.source)/\(sourceRecord.id)"
            record.buttonLabel = NSLocalizedString("View Record at Europe PMC", comment: "button, EPMC Document")
            record.smallButtonLabel = "Full Text"
            record.buttonColor = "blue"
        }
        
        
        if let journalTitle = sourceRecord.journalInfo?.journal.title{
            if (journalTitle != ""){
                record.source += "\(journalTitle)"
            }
        }
        if let year = sourceRecord.pubYear {
            if (year != ""){
                record.source += " (\(year))"
            }
        }
        
        if let volume = sourceRecord.journalInfo?.volume {
            if (volume != "") {
                record.source += ", Vol. \(volume)"
            }
        }
        if let issue = sourceRecord.journalInfo?.issue {
            if (issue != ""){
                record.source += ", Iss. \(issue)"
            }
        }
        if let pages = sourceRecord.pageInfo {
            if (pages != ""){
                record.source += ", p. \(pages)"
            }
        }
        return record
        
    }
    
    func createSearch(search: String) -> String{
        //TO DO: need to support AND, OR, NOT
        let andSearch = search.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: " AND ")
        let query = "title:((\(andSearch)) ) OR description:((\(andSearch)) )"
        
        return query
    }
    
    func validateProxyPrefix(urlString: String) -> Bool {
        let prefix = urlString.prefix(4)
        let suffix = urlString.suffix(5)
        let testService = "https://www.jstor.org"
        let testUrl = urlString+testService
        
        if(prefix != "http"){
            return false
        }
        if(suffix != "?url=" && suffix != "qurl=" && suffix != "&url="){
            return false
        }
        
        
        if let url = URL(string: testUrl) {
            let urlRequest = URLRequest.init(url: url)
            return NSURLConnection.canHandle(urlRequest)
        }
        return false
    }
    
}


