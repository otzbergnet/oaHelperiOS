//
//  coreRecommenderStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 30.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation


struct CoreRecommender : Decodable{
    var authors : [CoreRecommenderAuthor]
    var title : String
    var links : [CoreRecommenderLinks]?
    var yearPublished : Int?
    
}

struct CoreRecommenderLinks : Decodable{
    var type : String
    var url : String
}

struct CoreRecommenderAuthor : Decodable {
    var name : String
}

//struct CoreRecommendations : Decodable{
//    var title : String
//    var year : String
//    var author : String
//    var link : String
//}
