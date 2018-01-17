//
//  NSDate.swift
//  Hadith
//
//  Created by Majid Khan on 14/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

extension NSDate {
    
    func formatAsString(format : String = "dd/MM/yyyy HH:mm", timezoneAbbrev : String? = nil) -> String {
        let formatter = NSDateFormatter()
        if timezoneAbbrev != nil {
            formatter.timeZone = NSTimeZone(abbreviation: timezoneAbbrev!)
        }
        formatter.dateFormat = format
        return formatter.stringFromDate(self)
    }
    
    class func fromString(date : String, format : String = "dd/MM/yyyy HH:mm", timezoneAbbrev : String? = nil) -> NSDate? {
        let formatter = NSDateFormatter()
        if timezoneAbbrev != nil {
            formatter.timeZone = NSTimeZone(abbreviation: timezoneAbbrev!)
        } else {
            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        }
        formatter.dateFormat = format
        return formatter.dateFromString(date)
    }
}