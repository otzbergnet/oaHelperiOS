//
//  proxyStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 10.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Foundation

struct ProxyList : Decodable{
    var data : [ProxyInstitute] = []
    var code : Int = 0
    var count : Int = 0
}

struct ProxyInstitute : Decodable{
    var id = ""
    var institution = ""
    var proxyUrl = ""
    var ill = ""
    var domainUrl = ""
    var country = ""
}
