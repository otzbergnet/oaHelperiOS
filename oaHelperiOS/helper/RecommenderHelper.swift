//
//  RecommenderHelper.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 30.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation

class CoreRequestObject{
    var doi = ""
    var title = ""
    var aabstract = ""
    var author = ""
    var referer = ""
    var fulltextUrl = ""
}

class RecommenderHelper {
    
    let helper = HelperClass()
    
    func askForRecommendation(metaData : CoreRequestObject, completion: @escaping (Result<CoreRecommender, Error>) -> ()){
//        let timer = ParkBenchTimer()
//        print("ask for Core Recommendation")
        let apiKey = self.helper.getAPIKeyFromPlist(key: "coreRecommender")
        let apiEndPoint = self.helper.getAPIKeyFromPlist(key: "coreRecommenderUrl")
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
            "title" : metaData.title,
            "aabstract" : metaData.aabstract,
            "author" : metaData.author,
            "referer" : metaData.referer,
            "url" : metaData.fulltextUrl,
            "doi" : metaData.doi
        ]
        
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        let urlconfig = URLSessionConfiguration.default
        urlconfig.timeoutIntervalForRequest = 31
        urlconfig.timeoutIntervalForResource = 31
        
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
                    let recommendations = try JSONDecoder().decode(CoreRecommender.self, from: data)
                    //print("data received \(recommendations.code)")
                    completion(.success(recommendations))
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
    

    
}
