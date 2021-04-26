//
//  epmcStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 31.03.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import Foundation

struct EPMC : Decodable{
    let hitCount : Int?
    let nextCursorMark : String?
    let resultList : EpmcResult?
}

struct EpmcResult : Decodable {
    let result : [EpmcItems]
}

struct EpmcItems : Decodable {
    let id : String
    let source : String
    let pmcid : String?
    let title : String?
    let authorString : String?
    let pubYear : String?
    let pageInfo : String?
    let abstractText : String?
    let language : String?
    let isOpenAccess : String?
    let journalInfo : EpmcJournalInfo?
    let fullTextUrlList : FullTextUrlList?
}

struct EpmcJournalInfo : Decodable {
    let issue : String?
    let volume : String?
    let yearOfPublication : Int?
    let journal : EpmcJournal
}

struct EpmcJournal : Decodable {
    let title : String?
    let issn : String?
}

struct FullTextUrlList : Decodable {
    let fullTextUrl : [FullTextUrl]?
}

struct FullTextUrl : Decodable {
    let url : String?
    let availabilityCode : String?
    let documentStyle : String?
}
