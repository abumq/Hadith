//
//  Log.swift
//  Hadith
//
//  Created by Majid Khan on 27/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class Log {
    
    private static let enabled = false
    
    class func write(format: String, _ args: CVarArgType...) {
        if !Log.enabled {
            return
        }
        let line = String(format: format, arguments: args);
        print(line)
    }
    
    class func write(line : Any) {
        if !Log.enabled {
            return
        }
        print(line)
    }

}