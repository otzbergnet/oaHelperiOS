//
//  zoteroStructs.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 12.04.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import Foundation

struct ClientCredentials {
    let ClientKey: String
    let ClientSecret: String
    let CallbackURLScheme: String
}

struct TemporaryCredentials {
    let requestToken: String
    let requestTokenSecret: String
}

struct TokenCredentials {
    let accessToken: String
    let accessTokenSecret: String
    let userID : String
    let username : String
}

struct ZoteroCollections : Decodable{
    let key: String
    let data: ZoteroCollectionItem?
}

struct ZoteroCollectionItem : Decodable{
    let key: String
    let name: String
}

struct CreateZoteroCollection : Decodable {
    let success: CreateCollectionSuccess?
    let failed: CreateCollectionFailure?
}

struct CreateCollectionSuccess : Decodable {
    let the0: String?
    enum CodingKeys: String, CodingKey {
        case the0 = "0"
    }
}

struct CreateCollectionFailure : Decodable{
    let the0: ZoteroFailureObject?
    enum CodingKeys: String, CodingKey{
        case the0 = "0"
    }
}

struct ZoteroFailureObject : Decodable {
    let code: Int?
    let message: String?
}

struct ZoteroJournalArticle : Codable {
    var itemType = "journalArticle"
    var title: String
    var creators: [ZoteroCreator]
    var abstractNote: String
    var publicationTitle: String
    var volume: String
    var issue: String
    var pages: String
    var date: String
    var series: String
    var seriesTitle: String
    var seriesText: String
    var journalAbbreviation: String
    var language: String
    var doi: String
    var issn: String
    var shortTitle: String
    var url: String
    var accessDate: String
    var archive: String
    var archiveLocation: String
    var libraryCatalog: String
    var callNumber: String
    var rights: String
    var extra: String
    var collections: [String]
    var tags: [ZoteroTag]
}

struct ZoteroCreator : Codable {
    var creatorType = "author"
    var firstName: String
    var lastName: String
}

struct ZoteroTag : Codable {
    var tag: String
}

struct ZoteroWebPage : Codable {
    var itemType = "webpage"
    var title: String
    var accessDate: String
    var url: String
    var collections: [String]
    var tags: [ZoteroTag]
}

// for [ZoteroItem] in search results

struct ZoteroItem  : Codable {
    var key: String
    var version: Int
    var links: ZoteroLinks
    var data: ZoteroData
}

struct ZoteroLinks  : Codable {
    var alternate: ZoteroAlternate
}

struct ZoteroAlternate  : Codable {
    var href: String
}

struct ZoteroData  : Codable {
    var key: String
    var itemType: String
    var title: String
    var creators: [ZoteroCreator]?
    var publicationTitle: String?
    var volume: String?
    var issue: String?
    var pages: String?
    var date: String?
    var doi: String?
    var issn: String?
    var url: String?
}
