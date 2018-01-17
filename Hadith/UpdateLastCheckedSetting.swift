//
//  UpdateLastCheckedSetting.swift
//  Hadith
//
//  Created by Majid Khan on 11/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class UpdateLastCheckedSetting {
    
    var value : NSDate
    
    class func getSettingName() -> String {
        return "update-last-checked"
    }
    
    class func getDefault() -> UpdateLastCheckedSetting {
        return UpdateLastCheckedSetting()
    }
    
    class func load() -> UpdateLastCheckedSetting {
        let value = NSUserDefaults.standardUserDefaults().stringForKey(UpdateLastCheckedSetting.getSettingName())
        
        let setting = UpdateLastCheckedSetting.getDefault()
        if (value != nil) {
            if let d = NSDate.fromString(value!) {
                setting.value = d
            }
        }
        return setting
    }
    
    init() {
        self.value = NSDate.fromString("01/01/2016 00:00")!
    }
    
    func save() {
        NSUserDefaults.standardUserDefaults().setValue(self.formatAsString(), forKey: UpdateLastCheckedSetting.getSettingName())
    }
    
    func needsToRecheck(intervalInSeconds : Int) -> Bool {
        let lastUpdatedSeconds = -Int(self.value.timeIntervalSinceNow)
        return lastUpdatedSeconds > intervalInSeconds
    }
    
    func formatAsString() -> String {
        return self.value.formatAsString()
    }
}