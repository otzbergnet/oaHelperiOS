//
//  DateExtension.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 07.07.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation

extension Date {
    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
