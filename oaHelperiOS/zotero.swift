//
//  zotero.swift
//  zoteroTest
//
//  Created by Claus Wolf on 02.04.21.
//

import Foundation
import CommonCrypto



class ZoteroAPI: NSObject {
    
    let helper = HelperClass()
    var clientCredential = ClientCredentials(ClientKey: "", ClientSecret: "", CallbackURLScheme: "")
    
    override init() {
        let key = helper.getAPIKeyFromPlist(key: "zClientKey")
        let secret = helper.getAPIKeyFromPlist(key: "zClientSecret")
        let cb = helper.getAPIKeyFromPlist(key: "zCallBackSchema")
        clientCredential = ClientCredentials(ClientKey: key, ClientSecret: secret, CallbackURLScheme: cb)
    }
    
    enum OAuthError: Error {
        case unknown
        case urlError(URLError)
        case httpURLResponse(Int)
        case cannotDecodeRawData
        case cannotParseResponse
        case unexpectedResponse
        case failedToConfirmCallback
    }
    
    func oAuthRequestToken(start : Bool, completion: @escaping (Result<TemporaryCredentials, OAuthError>) -> ()) {
        let request = (baseURLString: "https://www.zotero.org/oauth/request",
                       httpMethod: "POST",
                       consumerKey: clientCredential.ClientKey,
                       consumerSecret: clientCredential.ClientSecret,
                       callbackURLString: "\(clientCredential.CallbackURLScheme)://")
        
        guard let baseURL = URL(string: request.baseURLString) else {
            completion(.failure(.urlError(URLError(.badURL))))
            return
        }
        
        var parameters = [
            URLQueryItem(name: "oauth_callback", value: request.callbackURLString),
            URLQueryItem(name: "oauth_consumer_key", value: request.consumerKey),
            URLQueryItem(name: "oauth_nonce", value: UUID().uuidString),
            URLQueryItem(name: "oauth_signature_method", value: "HMAC-SHA1"),
            URLQueryItem(name: "oauth_timestamp", value: String(Int(Date().timeIntervalSince1970))),
            URLQueryItem(name: "oauth_version", value: "1.0"),
        ]
        
        let signature = oAuthSignature(httpMethod: request.httpMethod,
                                       baseURLString: request.baseURLString,
                                       parameters: parameters,
                                       consumerSecret: request.consumerSecret)
        
        parameters.append(URLQueryItem(name: "oauth_signature", value: signature))
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = request.httpMethod
        urlRequest.setValue(oAuthAuthorizationHeader(parameters: parameters), forHTTPHeaderField: "Authorization")
        
        let urlconfig = URLSessionConfiguration.default
        
        let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
        
        let task = session.dataTask(with: urlRequest) {(data, response, error) in
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(OAuthError.unknown))
                return
            }
            
            guard response.statusCode == 200 else {
                completion(.failure(OAuthError.httpURLResponse(response.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(OAuthError.unknown))
                return
            }
            
            guard let parameterString = String(data: data, encoding: .utf8) else {
                completion(.failure(OAuthError.cannotDecodeRawData))
                return
            }
            
            if let parameters = parameterString.urlQueryItems {
                guard let oAuthToken = parameters["oauth_token"],
                      let oAuthTokenSecret = parameters["oauth_token_secret"],
                      let oAuthCallbackConfirmed = parameters["oauth_callback_confirmed"]
                else {
                    completion(.failure(OAuthError.unexpectedResponse))
                    return
                }
                
                if oAuthCallbackConfirmed != "true" {
                    completion(.failure(OAuthError.failedToConfirmCallback))
                }
                
                completion(.success(TemporaryCredentials(requestToken: oAuthToken, requestTokenSecret: oAuthTokenSecret)))
            }
            else {
                completion(.failure(OAuthError.cannotParseResponse))
            }
            
        }
        task.resume()
        
    }
    
    func oAuthAccessToken(temporaryCredentials: TemporaryCredentials, verifier: String, completion: @escaping (Result<TokenCredentials, OAuthError>) -> ()) {
        let request = (baseURLString: "https://www.zotero.org/oauth/access",
                       httpMethod: "POST",
                       consumerKey: clientCredential.ClientKey,
                       consumerSecret: clientCredential.ClientSecret)
        
        guard let baseURL = URL(string: request.baseURLString) else {
            completion(.failure(OAuthError.urlError(URLError(.badURL))))
            return
        }
        
        var parameters = [
            URLQueryItem(name: "oauth_token", value: temporaryCredentials.requestToken),
            URLQueryItem(name: "oauth_verifier", value: verifier),
            URLQueryItem(name: "oauth_consumer_key", value: request.consumerKey),
            URLQueryItem(name: "oauth_nonce", value: UUID().uuidString),
            URLQueryItem(name: "oauth_signature_method", value: "HMAC-SHA1"),
            URLQueryItem(name: "oauth_timestamp", value: String(Int(Date().timeIntervalSince1970))),
            URLQueryItem(name: "oauth_version", value: "1.0")
        ]
        
        let signature = oAuthSignature(httpMethod: request.httpMethod,
                                       baseURLString: request.baseURLString,
                                       parameters: parameters,
                                       consumerSecret: request.consumerSecret,
                                       oAuthTokenSecret: temporaryCredentials.requestTokenSecret)
        
        parameters.append(URLQueryItem(name: "oauth_signature", value: signature))
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = request.httpMethod
        urlRequest.setValue(oAuthAuthorizationHeader(parameters: parameters), forHTTPHeaderField: "Authorization")
        
        let urlconfig = URLSessionConfiguration.default
        
        let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
        
        let task = session.dataTask(with: urlRequest) {(data, response, error) in
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(OAuthError.unknown))
                return
            }
            
            guard response.statusCode == 200 else{
                completion(.failure(OAuthError.httpURLResponse(response.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(OAuthError.cannotDecodeRawData))
                return
            }
            
            guard let parameterString = String(data: data, encoding: .utf8) else {
                completion(.failure(OAuthError.cannotDecodeRawData))
                return
            }
            
            if let parameters = parameterString.urlQueryItems {
                guard let oAuthToken = parameters.value(for: "oauth_token"),
                      let oAuthTokenSecret = parameters.value(for: "oauth_token_secret"),
                      let userID = parameters.value(for: "userID"),
                      let screenName = parameters.value(for: "username")
                else {
                    completion(.failure(OAuthError.unexpectedResponse))
                    return
                }
                completion(.success(TokenCredentials(accessToken: oAuthToken, accessTokenSecret: oAuthTokenSecret, userID: userID, username: screenName)))
            } else {
                completion(.failure(OAuthError.cannotParseResponse))
                return
            }
            
        }
        task.resume()
    }
    
    func oAuthSignatureBaseString(httpMethod: String,
                                  baseURLString: String,
                                  parameters: [URLQueryItem]) -> String {
        var parameterComponents: [String] = []
        for parameter in parameters {
            let name = parameter.name.oAuthURLEncodedString
            let value = parameter.value?.oAuthURLEncodedString ?? ""
            parameterComponents.append("\(name)=\(value)")
        }
        let parameterString = parameterComponents.sorted().joined(separator: "&")
        return httpMethod + "&" +
            baseURLString.oAuthURLEncodedString + "&" +
            parameterString.oAuthURLEncodedString
    }
    
    func clearZoteroRelatedSettings(){
        let settings = SettingsBundleHelper()
        settings.setSettingsValue(value: false, key: "activeOAuth")
        settings.setSettingsValue(value: false, key: "zoteroSuccess")
        settings.setSettingsStringValue(value: "", key: "oauth_token")
        settings.setSettingsStringValue(value: "", key: "oauth_token_secret")
        settings.setSettingsStringValue(value: "", key: "userID")
        settings.setSettingsStringValue(value: "", key: "username")
    }
    
    func collectionExists(name: String, completion: @escaping (Result<Bool, NSError>) -> ()) {
        let settings = SettingsBundleHelper()
        let userId = settings.getSettingsStringValue(key: "userID")
        let oauthToken = settings.getSettingsStringValue(key: "oauth_token")
        
        let url = "https://api.zotero.org/users/\(userId)/collections"
        guard let baseURL = URL(string: url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "badUrl"])))
            return
        }
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue(oauthToken, forHTTPHeaderField: "Zotero-API-Key")
        
        let urlconfig = URLSessionConfiguration.default
        let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
        let task = session.dataTask(with: urlRequest) {(data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "failedHTTPResponse"])))
                return
            }
            
            guard response.statusCode == 200 else{
                completion(.failure(NSError(domain: "", code: response.statusCode, userInfo: ["description" : "notOK"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "dataNotPresent"])))
                return
            }
            
            do {
                let collections = try JSONDecoder().decode([ZoteroCollections].self, from: data)
                var exists = false
                for collection in collections {
                    exists = false
                    settings.setSettingsStringValue(value: "", key: "collectionID")
                    if let collectionData = collection.data {
                        if collectionData.name == name{
                            exists = true
                            settings.setSettingsStringValue(value: collectionData.key, key: "collectionID")
                        }
                    }
                }
                completion(.success(exists))
            }
            catch let jsonError{
                print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : jsonError])))
            }
            
        }
        task.resume()
    }
    
    func createCollection(name: String, completion: @escaping (Result<Bool, NSError>) -> ()) {
        let json : [String : Any] = [ "name" : name, "parentCollection" : "" ]
        let jsonArray = [json]
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)

        let settings = SettingsBundleHelper()
        let userId = settings.getSettingsStringValue(key: "userID")
        let oauthToken = settings.getSettingsStringValue(key: "oauth_token")
        
        let url = "https://api.zotero.org/users/\(userId)/collections"
        guard let baseURL = URL(string: url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "badUrl"])))
            return
        }
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(oauthToken, forHTTPHeaderField: "Zotero-API-Key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(randomString(length: 32), forHTTPHeaderField: "Zotero-Write-Token")
        urlRequest.httpBody = jsonData
        
        let urlconfig = URLSessionConfiguration.default
        let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
        let task = session.dataTask(with: urlRequest) {(data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "failedHTTPResponse"])))
                return
            }
            
            guard response.statusCode == 200 else{
                print(String(decoding: data!, as: UTF8.self))
                completion(.failure(NSError(domain: "", code: response.statusCode, userInfo: ["description" : "notOK"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "dataNotPresent"])))
                return
            }
            
            do {
                let collection = try JSONDecoder().decode(CreateZoteroCollection.self, from: data)
                var exists = false
                if let success = collection.success {
                    if success.the0 != "" {
                        settings.setSettingsStringValue(value: success.the0, key: "collectionID")
                        exists = true
                    }
                }
                
                completion(.success(exists))
            }
            catch let jsonError{
                print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : jsonError])))
            }
            
        }
        task.resume()
    
    }
    
    func addZoteroItem(record: ZoteroJournalArticle? = nil, webPage: ZoteroWebPage? = nil, completion: @escaping (Result<Bool, NSError>) -> ()) {
        if record == nil && webPage == nil {
            completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "you need either an article record or a webpage record object"])))
            return
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            var jsonData = Data()
            if record != nil {
                jsonData = try encoder.encode([record])
            }
            else if webPage != nil {
                jsonData = try encoder.encode([webPage])
            }

            let settings = SettingsBundleHelper()
            let userId = settings.getSettingsStringValue(key: "userID")
            let oauthToken = settings.getSettingsStringValue(key: "oauth_token")
            
            let url = "https://api.zotero.org/users/\(userId)/items"
            guard let baseURL = URL(string: url) else {
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "badUrl"])))
                return
            }
            
            var urlRequest = URLRequest(url: baseURL)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue(oauthToken, forHTTPHeaderField: "Zotero-API-Key")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(randomString(length: 32), forHTTPHeaderField: "Zotero-Write-Token")
            urlRequest.httpBody = jsonData
            
            let urlconfig = URLSessionConfiguration.default
            let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
            let task = session.dataTask(with: urlRequest) {(data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "failedHTTPResponse"])))
                    return
                }
                
                guard response.statusCode == 200 else{
                    print(String(decoding: data!, as: UTF8.self))
                    completion(.failure(NSError(domain: "", code: response.statusCode, userInfo: ["description" : "notOK"])))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "dataNotPresent"])))
                    return
                }
                
                do {
                    let item = try JSONDecoder().decode(CreateZoteroCollection.self, from: data)
                    var exists = false
                    if let success = item.success {
                        if success.the0 != "" {
                            exists = true
                        }
                    }
                    
                    completion(.success(exists))
                }
                catch let jsonError{
                    print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                    completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : jsonError])))
                }
                
            }
            task.resume()
        } catch {
            print(error.localizedDescription)
        }


    }
    
    func convertCrossRef2Zotero(record: CrossRef, url: String) -> ZoteroJournalArticle{
        let settings = SettingsBundleHelper()
        let zoteroJournalArticle = ZoteroJournalArticle(
            itemType: "journalArticle",
            title: record.message.title.first?.description ?? "",
            creators: self.makeZoteroCreators(record: record),
            abstractNote: record.message.abstract ?? "",
            publicationTitle: record.message.containerTitle.first?.description ?? "",
            volume: record.message.volume ?? "",
            issue: record.message.issue ?? "",
            pages: record.message.page ?? "",
            date: record.message.created.dateTime,
            series: "",
            seriesTitle: "",
            seriesText: "",
            journalAbbreviation: record.message.shortContainerTitle.first?.description ?? "",
            language: record.message.language ?? "",
            doi: record.message.doi,
            issn: record.message.issn?.first?.description ?? "",
            shortTitle: "",
            url: url,
            accessDate: self.makeZoteroDate(),
            archive: "",
            archiveLocation: "",
            libraryCatalog: "",
            callNumber: "",
            rights: "",
            extra: "",
            collections: [settings.getSettingsStringValue(key: "collectionID")],
            tags: self.makeZoteroTag(record: record)
        )
        return zoteroJournalArticle
    }
    
    func makeZoteroWebPage(title: String, url: String) -> ZoteroWebPage{
        let settings = SettingsBundleHelper()
        let zoteroWebPage = ZoteroWebPage(
            title: title,
            accessDate: self.makeZoteroDate(),
            url: url,
            collections: [settings.getSettingsStringValue(key: "collectionID")],
            tags: self.makeEmptyZoteroTag()
        )
        return zoteroWebPage
    }
    
    func makeZoteroTag(record: CrossRef) -> [ZoteroTag] {
        var zoteroTags = [ZoteroTag]()
        let zoteroTag = ZoteroTag(tag: "OAHelper")
        zoteroTags.append(zoteroTag)
        if let subjects = record.message.subject {
            for subject in subjects {
                let zoteroTag = ZoteroTag(tag: subject)
                zoteroTags.append(zoteroTag)
            }
        }
        return zoteroTags
    }
    func makeEmptyZoteroTag() -> [ZoteroTag] {
        var zoteroTags = [ZoteroTag]()
        let zoteroTag = ZoteroTag(tag: "OAHelper")
        zoteroTags.append(zoteroTag)
        return zoteroTags
    }
    
    func makeZoteroCreators(record: CrossRef) -> [ZoteroCreator] {
        var zoteroCreators = [ZoteroCreator]()
        for author in record.message.author {
            let zoteroAuthor = ZoteroCreator(creatorType: "author", firstName: author.given ?? "", lastName: author.family ?? "")
            zoteroCreators.append(zoteroAuthor)
        }
        return zoteroCreators
    }
    
    func makeZoteroDate() -> String{
        let formatter = ISO8601DateFormatter()
        let string = formatter.string(from: Date())
        return string
    }
    
    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    private func oAuthSigningKey(consumerSecret: String,
                                 oAuthTokenSecret: String?) -> String {
        if let oAuthTokenSecret = oAuthTokenSecret {
            return consumerSecret.oAuthURLEncodedString + "&" +
                oAuthTokenSecret.oAuthURLEncodedString
        } else {
            return consumerSecret.oAuthURLEncodedString + "&"
        }
    }
    
    private func oAuthSignature(httpMethod: String,
                                baseURLString: String,
                                parameters: [URLQueryItem],
                                consumerSecret: String,
                                oAuthTokenSecret: String? = nil) -> String {
        let signatureBaseString = oAuthSignatureBaseString(httpMethod: httpMethod,
                                                           baseURLString: baseURLString,
                                                           parameters: parameters)
        
        let signingKey = oAuthSigningKey(consumerSecret: consumerSecret,
                                         oAuthTokenSecret: oAuthTokenSecret)
        
        return signatureBaseString.hmacSHA1Hash(key: signingKey)
    }
    
    private func oAuthAuthorizationHeader(parameters: [URLQueryItem]) -> String {
        var parameterComponents: [String] = []
        for parameter in parameters {
            let name = parameter.name.oAuthURLEncodedString
            let value = parameter.value?.oAuthURLEncodedString ?? ""
            parameterComponents.append("\(name)=\"\(value)\"")
        }
        return "OAuth " + parameterComponents.sorted().joined(separator: ", ")
    }
}

extension CharacterSet {
    static var urlRFC3986Allowed: CharacterSet {
        CharacterSet(charactersIn: "-_.~").union(.alphanumerics)
    }
}

extension String {
    var oAuthURLEncodedString: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlRFC3986Allowed) ?? self
    }
}

extension String {
    var urlQueryItems: [URLQueryItem]? {
        URLComponents(string: "://?\(self)")?.queryItems
    }
}

extension Array where Element == URLQueryItem {
    func value(for name: String) -> String? {
        return self.filter({$0.name == name}).first?.value
    }
    
    subscript(name: String) -> String? {
        return value(for: name)
    }
}

extension String {
    func hmacSHA1Hash(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
               key,
               key.count,
               self,
               self.count,
               &digest)
        return Data(digest).base64EncodedString()
    }
}
