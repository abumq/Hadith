//
//  StringSetting.swift
//  Hadith
//
//  Created by Majid Khan on 13/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class Setting<T> {
    
    class func getSettingName() -> String {
        fatalError("Not implemented")
    }
    
    class func getDefault() -> T? {
        return nil
    }
    
    class func load() -> T? {
        let result = NSUserDefaults.standardUserDefaults().objectForKey(getSettingName())
        return result == nil ? self.getDefault() : result as? T
    }
    
    class func save(val : T) {
        if let value = val as? AnyObject {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: getSettingName())
        } else if let value = val as? Bool {
            NSUserDefaults.standardUserDefaults().setBool(value, forKey: getSettingName())
        } else if let value = val as? Int {
            NSUserDefaults.standardUserDefaults().setInteger(value, forKey: getSettingName())
        } else {
            fatalError("T cannot be resolved for setting")
        }
    }
}