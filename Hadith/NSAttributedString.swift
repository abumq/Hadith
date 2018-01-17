//
//  NSAttributedString.swift
//  Hadith
//
//  Created by Majid Khan on 12/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {
    func replaceHTMLTag(tag: String, withAttributes attributes: [String: AnyObject]) -> NSAttributedString {
        let openTag = "<\(tag)>"
        let closeTag = "</\(tag)>"
        let resultingText: NSMutableAttributedString = self.mutableCopy() as! NSMutableAttributedString
        while true {
            let plainString = resultingText.string as NSString
            let openTagRange = plainString.rangeOfString(openTag)
            if openTagRange.length == 0 {
                break
            }
            
            let affectedLocation = openTagRange.location + openTagRange.length
            
            let searchRange = NSMakeRange(affectedLocation, plainString.length - affectedLocation)
            
            let closeTagRange = plainString.rangeOfString(closeTag, options: NSStringCompareOptions(rawValue: 0), range: searchRange)
            
            resultingText.setAttributes(attributes, range: NSMakeRange(affectedLocation, closeTagRange.location - affectedLocation))
            resultingText.deleteCharactersInRange(closeTagRange)
            resultingText.deleteCharactersInRange(openTagRange)
        }
        return resultingText as NSAttributedString
    }
    
    
}

extension NSMutableAttributedString {
    func highlight(list : [String]) {
        for str in list {
            let regex = str
            if let regex = try? NSRegularExpression(pattern: regex, options: .CaseInsensitive) {
                
                for match in regex.matchesInString(self.string, options: [], range: NSRange(location: 0, length: self.string.utf16.count)) {
                    
                    self.addAttribute(NSBackgroundColorAttributeName, value: UIColor.yellowColor(), range: match.range)
                    
                }
            }

        }
    }
}