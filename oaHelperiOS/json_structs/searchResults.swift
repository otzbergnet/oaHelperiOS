//
//  searchResults.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 31.03.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import Foundation

class SearchResult{
    var service : String = ""
    var hitCount : Int = 0
    var maxPage : Int = 0
    var page : Int = 0
    var token : String = ""
    var records = [SearchResultRecords]()
}

class SearchResultRecords {
    var num : Int = 0
    var title : String = ""
    var author : String = ""
    var source : String = ""
    var year : String = ""
    var abstract : String = ""
    var hasFT : Bool = false
    var linkUrl : String = ""
    var buttonLabel : String = ""
}
