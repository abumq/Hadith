//
//  SwipeStyleSetting.swift
//  Hadith
//
//  Created by Majid Khan on 17/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

enum SwipeStyleSetting : Int {
    case Page = 1
    case Scroll = 2
    
    static func getSettingName() -> String {
        return "swipe-style"
    }
    
    static func getDefault() -> SwipeStyleSetting {
        return .Page
    }
    
    static func load() -> SwipeStyleSetting {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(SwipeStyleSetting.getSettingName())
        if let setting = SwipeStyleSetting(rawValue: value) {
            return setting
        }
        return SwipeStyleSetting.getDefault()
    }
    
    func save() {
        NSUserDefaults.standardUserDefaults().setInteger(self.rawValue, forKey: SwipeStyleSetting.getSettingName())
    }
}