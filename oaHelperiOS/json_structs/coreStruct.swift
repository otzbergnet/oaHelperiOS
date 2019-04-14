//
//  coreStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 15.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Foundation

struct Core : Decodable{
    let status : String
    let totalHits : Int?
    let data : [Items]?
}

struct Items : Decodable{
    let id : String?
    let authors : [String]?
    let citations : [Citations]?
    let contributors : [String]?
    let datePublished : String?
    let description : String?
    let identifieres : [String]?
    let journals : [Journals]?
    let relations : [String]?
    let repositories : [Repositories]?
    let repositoryDocument : RepositoryDocument?
    let subjects : [String]?
    let title : String?
    let topics : [String]?
    let types : [String]?
    let year : Int?
    let fulltextUrls : [String]?
    let fullTextIdentifier : String?
    let doi : String?
    let oai : String?
    let downloadUrl : String?
}

struct Citations : Decodable{
    let raw : String?
    let authors : [String]?
    let title : String?
    let date : String?
    let doi : String?
}


struct Journals : Decodable{
    let title : String?
    let identifiers : [String]?
}

struct Language : Decodable{
    let code : String
    let name : String
}

struct Repositories : Decodable{
    let id : String?
    let openDoarId : Int?
    let name : String?
    let uri : String?
    let urlHomepage : String?
    let urlOaipmh : String?
    let uriJournals : String?
    let physicalName : String?
    let source : String?
    let software : String?
    let metadataFormat : String?
    let description : String?
    let journal : String?
    let roarId : Int?
    let pdfStatus : String?
    let nrUpdates : Int?
    let disabled : Bool?
    let lastUpdateTime : String?
    let repositoryLocation : RepositoryLocation?
    let repositoryStats : RepositoryStats?
}

struct RepositoryDocument : Decodable{
    let pdfStatus : Int?
    let textStatus : Int?
    let metadataAdded : Int?
    let metadataUpdated : Int?
    let timestamp : Int?
    let depositedDate : Int?
    let indexed : Int?
    let deletedStatus : String?
    let pdfSize : Int?
    let tdmOnly : Bool?
    let pdfOrigin : String?
}

struct RepositoryLocation : Decodable{
    let id_repository : Int?
    let repository_name : String?
    let country : String?
    let latitude : Int?
    let logitude : Int?
    let country_code : String?
}

struct RepositoryStats : Decodable{
    let date_last_processed : String?
    let count_metadata : Int?
    let count_fulltext : Int?
}

struct Similar : Decodable{
    let id : Int?
    let title : String?
    let score : Double
}

