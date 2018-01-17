//
//  UIColor.swift
//  Hadith
//
//  Created by Majid Khan on 9/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static func appThemeColorLight() -> UIColor {
        return UIColor(hexString:"#91251c")
    }
    
    static func appThemeTintColor() -> UIColor {
        return UIColor(hexString:"#a80000")
    }
    
    static func appThemeColorDark() -> UIColor {
        return UIColor(hexString:"#3f0e0a")
    }
    
    static func appThemeBackground() -> UIColor {
        return UIColor.whiteColor()
    }
    
    convenience init (hexString:String) {
        var cleanString:String = hexString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cleanString.hasPrefix("#")) {
            cleanString = cleanString.substringFrom(1)
        }
        
        if (cleanString.characters.count != 6) {
            self.init()
        }
        else{
            var rgbValue = UInt32()
            let scanner = NSScanner(string: cleanString)
            scanner.scanHexInt(&rgbValue)
            
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0,
                green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0,
                blue: CGFloat(rgbValue & 0xFF)/255.0,
                alpha: 1.0)
        }
    }
}