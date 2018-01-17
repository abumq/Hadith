//
//  AutoUpdateSetting.swift
//  Hadith
//
//  Created by Majid Khan on 6/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

enum AutoUpdateSetting : Int {
    case Never = 1
    case WiFi = 2
    case WiFiCellular = 3
    
    static func getSettingName() -> String {
        return "auto-update"
    }
    
    static func getDefault() -> AutoUpdateSetting {
        return .WiFi
    }
    
    static func load() -> AutoUpdateSetting {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(AutoUpdateSetting.getSettingName())
        if let setting = AutoUpdateSetting(rawValue: value) {
            return setting
        }
        return AutoUpdateSetting.getDefault()
    }
    
    func save() {
        NSUserDefaults.standardUserDefaults().setInteger(self.rawValue, forKey: AutoUpdateSetting.getSettingName())
    }
}