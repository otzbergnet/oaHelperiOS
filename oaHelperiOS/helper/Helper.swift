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
        let smallPhones = ["iPhone8,4","iPhone6,1","iPhone6,2","iPhone5,1","iPhone5,2","iPhone5,3","iPhone5,4","iPhone4,1","iPhone3,1", "iPhone3,2", "iPhone3,3", "iPhone2,1", "iPhone1,2"]
        let model = modelIdentifier()
        if(smallPhones.contains(model)){
            return true
        }
        else{
            return false
        }
    }
    
    func recentSynced(lastDate: String) -> Bool{
        if(lastDate == "0"){
            return false
        }
        var returnValue = false
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let oldDate = dateFormatter.date(from: lastDate) {
            let newDate = Date()
            if let diffInHours = Calendar.current.dateComponents([.hour], from: oldDate, to: newDate).hour {
                if(diffInHours < 2){
                    returnValue = true
                }
            }
        }
        return returnValue
    }
    
    func recentNewsSynced(lastDate: String) -> Bool{
        if(lastDate == "0"){
            return false
        }
        var returnValue = false
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let oldDate = dateFormatter.date(from: lastDate) {
            let newDate = Date()
            if let diffInDays = Calendar.current.dateComponents([.hour], from: oldDate, to: newDate).day {
                if(diffInDays < 5){
                    returnValue = true
                }
            }
        }
        return returnValue
    }
 
    func replaceZeroWithUndersore(value : Int) -> String {
        var returnValue = ""
        if(value == 0){
            returnValue = "_"
        }
        else{
            returnValue = "\(value)"
        }
        return returnValue
    }
}


