//
//  OpenCitationHelper.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 21.03.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Foundation

class OpenCitationHelper {
    
    func findCitations(doi : String, completion: @escaping (Result<OpenCitationStruct, Error>) -> ()){
        //print("finding Citations")
        let urlString = "https://opencitations.net/index/api/v1/citation-count/\(doi)"
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in

            if let error = error{
                //we got an error, let's tell the user
                print("error")
                completion(.failure(error))
                print(error)
            }
            if let data = data {
                //this worked just fine
                do {
                    let openCitations = try JSONDecoder().decode([OpenCitationStruct].self, from: data)
                    if(openCitations.count > 0){
                        //print("data received \(openCitations.first!.count)")
                        completion(.success(openCitations.first!))
                    }
                    else{
                        print("Successful decode with 0 elements, should be impossible to be honest")
                        completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "failed to get any objects"])))
                    }
                    
                }
                catch let jsonError{
                    print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                    completion(.failure(jsonError))
                }
            }
            else{
                //another error
                print("failed to get data")
                completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "failed to get data"])))
                return
            }
            
        }.resume()
        
    }
    

    
}
