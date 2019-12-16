//
//  oadoiStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 08.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Foundation


struct OaDOI : Decodable {
    let url : String
    let status : String
}

struct Unpaywall : Decodable{
    let best_oa_location : OpenAccessLocation?
    let data_standard : Int?
    let doi : String
    let doi_url : String
    let genre : String
    let is_oa : Bool
    let journal_is_in_doaj: Bool
    let journal_is_oa : Bool
    let journal_issns : String?
    let journal_name : String?
    let oa_locations : [OpenAccessLocation]
    let published_date : String?
    let publisher : String?
    let title : String?
    let updated : String?
    let year : Int?
    let z_authors : [OAAuthors]?
}

struct OpenAccessLocation : Decodable {
    let evidence : String
    let host_type : String
    let is_best : Bool
    let license : String?
    let pmh_id : String?
    let updated : String?
    let url : String
    let url_for_landing_page : String?
    let url_for_pdf : String?
    let version : String?
}

struct OAAuthors : Decodable{
    
    let orcid : String?
    let authenticated_orcid : Bool?
    let family : String?
    let given : String?
    let sequence : String?
    
    enum CodingKeys: String, CodingKey {
        case authenticated_orcid = "authenticated-orcid"
        case orcid = "ORCID"
        case family = "family"
        case given = "given"
        case sequence = "sequence"
    }
    
}
