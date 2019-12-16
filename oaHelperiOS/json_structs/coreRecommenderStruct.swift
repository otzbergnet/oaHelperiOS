//
//  coreRecommenderStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 30.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation


struct CoreRecommender : Decodable{
    var msg : String
    var code : Int
    var data : [CoreRecommendations]
}

struct CoreRecommendations : Decodable{
    var title : String
    var year : String
    var author : String
    var link : String
}
