//
//  Helper.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 05.01.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class HelperClass {
  
    
    func cleanAbstract(txt: String) -> String{
        let toClean = ["&lt;p&gt;", "&lt;em&gt;", "&lt;/p&gt;", "&lt;/em&gt;", "\\ud", "&gt", "<p>", "<it>", "</it>", "&lt;em", "Abstract</p>"]
        var mytxt = txt;
        for token in toClean{
            mytxt = mytxt.replacingOccurrences(of: token, with: "")
        }
        let spaceCharacter = ["\r\n"]
        for space in spaceCharacter{
            mytxt = mytxt.replacingOccurrences(of: space, with: " ")
        }
        let lineBreak = ["\n\n\n", "\n\n", "\n", "</p> ", "</p>", "</p"]
        for abreak in lineBreak{
            mytxt = mytxt.replacingOccurrences(of: abreak, with: "\n")
        }
        
        return mytxt
    }
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    func isSE() -> Bool{
        if(modelIdentifier() == "iPhone8,4"){
            return true
        }
        else{
            return false
        }
    }
    
}


