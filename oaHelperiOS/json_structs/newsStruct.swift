//
//  newsStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 28.04.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation

struct News : Decodable{
    let item : [NewsItem]
}

struct NewsItem : Decodable {
    var id : Int16
    var update : Bool
    var delete : Bool
    var date : String
    var title : String
    var body : String
}

struct NewsItemItem : Decodable {
    var id : Int16 = 0
    var update : Bool = false
    var delete : Bool = false
    var read : Bool = false
    var date : String = "\(Date())"
    var title : String = ""
    var body : String = ""
}
