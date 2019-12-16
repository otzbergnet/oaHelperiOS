//
//  Timer.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 15.12.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Foundation
class ParkBenchTimer {

    let startTime:CFAbsoluteTime
    var endTime:CFAbsoluteTime?

    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()

        return duration!
    }

    var duration:CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}
