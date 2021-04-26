//
//  crossRefStruct.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 11.04.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import Foundation

// MARK: - CrossRef
struct CrossRef: Codable {
    let status: String
    let message: Message
}

// MARK: - Message
struct Message: Codable {
    let publisher: String?
    let issue: String?
    let shortContainerTitle: [String]
    let publishedPrint: Issued?
    let abstract : String?
    let doi, type: String
    let created: Created
    let page: String?
    let title: [String]
    let volume: String?
    let author: [Author]
    let member: String
    let containerTitle: [String]
    let language: String?
    let link: [Link]
    let subtitle, shortTitle: [String]
    let issued: Issued
    let issn: [String]?
    let subject: [String]?

    enum CodingKeys: String, CodingKey {
        case publisher
        case issue
        case shortContainerTitle = "short-container-title"
        case publishedPrint = "published-print"
        case abstract
        case doi = "DOI"
        case type, created, page
        case title
        case volume, author, member
        case containerTitle = "container-title"
        case language, link, subtitle
        case shortTitle = "short-title"
        case issued
        case issn = "ISSN"
        case subject
    }
}

// MARK: - Author
struct Author: Codable {
    let given, family: String?
}

// MARK: - Created
struct Created: Codable {
    let dateParts: [[Int]]
    let dateTime: String
    let timestamp: Int

    enum CodingKeys: String, CodingKey {
        case dateParts = "date-parts"
        case dateTime = "date-time"
        case timestamp
    }
}

// MARK: - Issued
struct Issued: Codable {
    let dateParts: [[Int]]

    enum CodingKeys: String, CodingKey {
        case dateParts = "date-parts"
    }
}



// MARK: - Link
struct Link: Codable {
    let url: String
    let contentType, contentVersion, intendedApplication: String

    enum CodingKeys: String, CodingKey {
        case url = "URL"
        case contentType = "content-type"
        case contentVersion = "content-version"
        case intendedApplication = "intended-application"
    }
}



