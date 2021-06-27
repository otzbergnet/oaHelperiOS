//
//  ProxyFind.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 10.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Foundation

class ProxyFind {
    
    let helper = HelperClass()
    let settings = SettingsBundleHelper()
        
    func askForProxy(domain : String, queryType: String, completion: @escaping (Result<[ProxyInstitute], Error>) -> ()){
            let apiKey = self.helper.getAPIKeyFromPlist(key: "coreRecommender")
            let apiEndPoint = self.helper.getAPIKeyFromPlist(key: "proxyApi")
            if (apiKey == "") {
                //print("no API Key")
                completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "no APIKey Present"])))
                return
            }
            if(apiEndPoint == ""){
                //print("no API EndPoint")
                completion(.failure(NSError(domain: "", code: 442, userInfo: ["description" : "no API End Point Present"])))
                return
            }
            let jsonUrlString = apiEndPoint
            guard let url = URL(string: jsonUrlString) else {
                //print("could not create URL")
                completion(.failure(NSError(domain: "", code: 443, userInfo: ["description" : "could not create URL"])))
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "X-Token")
            request.httpMethod = "POST"
                    
            let parameters: [String: Any] = [
                queryType : domain
            ]
            
            request.httpBody = parameters.percentEscaped().data(using: .utf8)
            let urlconfig = URLSessionConfiguration.default
            urlconfig.timeoutIntervalForRequest = 10
            urlconfig.timeoutIntervalForResource = 10
            
            let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
            
            let task = session.dataTask(with: request) {(data, response, error) in
    //            print("The core recommender task took \(timer.stop()) seconds.")
                if let error = error{
                    //we got an error, let's tell the user
                    //print("error")
                    completion(.failure(error))
                    print(error)
                }
                if let data = data {
                    //this worked just fine
                    do {
                        let proxyList = try JSONDecoder().decode(ProxyList.self, from: data)
                        if(proxyList.count == 0){
                            completion(.success(proxyList.data))
                        }
                        else if(proxyList.count > 0){
                            completion(.success(proxyList.data))
                        }
                        else{
                            completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "No match found"])))
                        }
                        
                    }
                    catch let jsonError{
                        //print(data)
                        //print("json decode error", jsonError)
                        print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                        completion(.failure(jsonError))
                    }
                }
                else{
                    //another error
                    //print("failed to get data")
                    completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "failed to get data"])))
                    return
                }
                
            }
            task.resume()
            
        }
    
    
    
    
    func  processProxyList(proxyList: [ProxyInstitute], completion: @escaping (Result<[Bool], Error>) -> ()){
        if let proxyPrefix = proxyList.first?.proxyUrl.replacingOccurrences(of: "{targetUrl}", with: ""){
            self.settings.setSettingsStringValue(value: proxyPrefix, key: "proxyPrefix")
            if(proxyPrefix != ""){
                self.settings.setSettingsValue(value: true, key: "useProxy")
            }
            if let instituteId = proxyList.first?.id{
                self.settings.setSettingsStringValue(value: instituteId, key: "instituteId")
            }
            if let illUrl = proxyList.first?.ill.replacingOccurrences(of: "{doi}", with: "") {
                self.settings.setSettingsStringValue(value: illUrl, key: "illUrl")
                if(illUrl != ""){
                    self.settings.setSettingsValue(value: true, key: "useIll")
                }
            }
            if let domainUrl = proxyList.first?.domainUrl {
                self.settings.setSettingsStringValue(value: domainUrl, key: "domainUrl")
                if(domainUrl != ""){
                    self.saveDomains()
                }
                else {
                    self.clearDomains()
                }
            }
            self.settings.setSettingsStringValue(value: "\(NSDate().timeIntervalSince1970)", key: "lastUpdate")
            completion(.success([true]))
        }
        else{
            completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "no valid proxyPrefix found"])))
        }
        
    }
    
    func saveDomains() {
        DispatchQueue.main.async {
            let domainHelper = DomainHelper()
            domainHelper.saveDomainList() { (res2) in
                switch res2 {
                case .success(_):
                    print("successfully saved domainList")
                case .failure(_):
                    print("failure while saving domainList")
                }
            }
        }
    }
    
    func clearDomains(){
        DispatchQueue.main.async {
            let domainHelper = DomainHelper()
            domainHelper.clearDomainList() { (res2) in
                switch res2 {
                case .success(_):
                    print("successfully cleared domainList")
                case .failure(_):
                    print("failure while clearing domainList")
                }
            }
        }
    }
    
}
