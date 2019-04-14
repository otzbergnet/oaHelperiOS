//
//  dessimStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 13.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Foundation

struct Dessim : Decodable{

    let stats : Stats
    let messages : [Messages]
    let nb_results : String
    let papers : [Papers]
    
}

struct Stats : Decodable{
    let detailed : [DetailedStats]
    let aggregated : [AggregatedStats]
}

struct DetailedStats : Decodable{
    let id : String
    let value : Int
    let label : String
}

struct AggregatedStats : Decodable{
    let label : String
}

struct Messages : Decodable{
    
}

struct Papers : Decodable{
    let classification : String
    let title : String
    let pdf_url : String?
    let records : [Records]
    let authors : [Authors]
    let date : String
    let type : String
}

struct Records : Decodable{
    let splash_url : String
    let doi : String?
    let publisher : String?
    let journal : String?
    let issn : String?
    let volume : String?
    let identifier : String
    let source : String
    let pages : String?
    let type : String
    let policy : Policy?
    
}

struct Authors : Decodable {
    let affiliation : String?
    let name : Name
}

struct Name : Decodable{
    let last : String
    let first : String
}

struct Policy : Decodable{
    let romeo_id : String
    let preprint : String
    let postprint : String
    let published : String
}
