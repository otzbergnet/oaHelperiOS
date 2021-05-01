//
//  BartyCrouch.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 11.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Foundation

enum BartyCrouch {
    enum SupportedLanguage: String {
        case english = "en"
        case german = "de"
    }

    static func translate(key: String, translations: [SupportedLanguage: String], comment: String? = nil) -> String {
        let typeName = String(describing: BartyCrouch.self)
        let methodName = #function

        print(
            "Warning: [BartyCrouch]",
            "Untransformed \(typeName).\(methodName) method call found with key '\(key)' and base translations '\(translations)'.",
            "Please ensure that BartyCrouch is installed and configured correctly."
        )

        // fall back in case something goes wrong with BartyCrouch transformation
        return "BC: TRANSFORMATION FAILED!"
    }
}
