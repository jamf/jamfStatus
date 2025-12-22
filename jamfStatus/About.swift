//
//  About.swift
//  jamfStatus
//
//  Created by leslie on 12/21/25.
//  Copyright © 2025 Leslie Helou. All rights reserved.
//

import AppKit
import Foundation

let supportText = """
This application helps identify how items are used/scoped. Identifies how/where items like extension attributes, scripts, packages, configuration payloads are used.

By default Object Info sends basic hardware, OS, and usage data for the app. Data is sent anonymously to https://telemetrydeck.com and used to aid in application development. To disable the sending of data click the 'Opt out of analytics' below.

"""

let feedback = """

Please share feedback by filing an issue.

"""

let warningText = """

Due to occasional changes to the API and introduction of new items the results may not include some items.

"""

let agreementText = """
    
This software is licensed under the terms of the Jamf Concepts Use Agreement

Copyright xxxx, Jamf Software, LLC.
"""

public func formattedText() -> NSAttributedString {
    print("formattedText")
    let basicFont = NSFont.systemFont(ofSize: 12)
    let basicAttributes = [NSAttributedString.Key.font: basicFont, .foregroundColor: defaultTextColor]
    let supportText = NSMutableAttributedString(string: supportText, attributes: basicAttributes)
    
    let tdRange  = supportText.mutableString.range(of: "https://telemetrydeck.com")
    if tdRange.location != NSNotFound {
        supportText.addAttribute(NSAttributedString.Key.link, value: "https://telemetrydeck.com", range: tdRange)
    }
    
    let aboutString = supportText
    
    let currentYear = "\(Calendar.current.component(.year, from: Date()))"
    
    let feedbackString = NSMutableAttributedString(string: feedback, attributes: basicAttributes)
    
    let issuesRange  = feedbackString.mutableString.range(of: "filing an issue")
    if issuesRange.location != NSNotFound {
        feedbackString.addAttribute(NSAttributedString.Key.link, value: "https://github.com/jamf/jamfStatus/issues", range: issuesRange)
    }
    aboutString.append(feedbackString)
    
    let warningFont = NSFont(name: "HelveticaNeue-Italic", size: 12)
//        let warningFont = NSFont.systemFont(ofSize: 12)
    let warningAttributes = [NSAttributedString.Key.font: warningFont, .foregroundColor: defaultTextColor]
    let warningString = NSMutableAttributedString(string: warningText, attributes: warningAttributes as [NSAttributedString.Key : Any])
    aboutString.append(warningString)
    
    let agreementString = NSMutableAttributedString(string: agreementText.replacingOccurrences(of: "Copyright xxxx", with: "Copyright \(currentYear)"), attributes: basicAttributes)
    let foundRange        = agreementString.mutableString.range(of: "Jamf Concepts Use Agreement")
    if foundRange.location != NSNotFound {
        agreementString.addAttribute(NSAttributedString.Key.link, value: "https://resources.jamf.com/documents/jamf-concept-projects-use-agreement.pdf", range: foundRange)
    }
    aboutString.append(agreementString)
    
    return aboutString
}
