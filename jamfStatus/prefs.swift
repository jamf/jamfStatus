//
//  prefs.swift
//  jamfStatus
//
//  Created by Leslie Helou on 4/20/17.
//  Copyright © 2017 Leslie Helou. All rights reserved.
//

import Foundation

class Prefs: NSObject {
    let myBundlePath = Bundle.main.bundlePath
    let SettingsPlistPath = Bundle.main.bundlePath+"/settings.plist"
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list file
    
    var settingsPlistData:[String:AnyObject] = [:]
    
    func readSettings(object: String) -> AnyObject {
        let plistXML = FileManager.default.contents(atPath: SettingsPlistPath)!
        do{
            settingsPlistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                                       options: .mutableContainersAndLeaves,
                                                                       format: &format)
                as! [String:AnyObject]
        } catch {
            //writeToLog(theMessage: "Error reading plist: \(error), format: \(format)")
        }
        let theSetting = settingsPlistData[object]
        return theSetting as AnyObject
    }
}
