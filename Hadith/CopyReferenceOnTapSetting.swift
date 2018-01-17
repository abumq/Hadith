//
//  CopyReferenceOnTapSetting.swift
//  Hadith
//
//  Created by Majid Khan on 5/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class CopyReferenceOnTapSetting : Setting<Bool> {
    
    override class func getDefault() -> Bool? {
        return false
    }
    
    override class func getSettingName() -> String {
        return "copy-ref-on-tap"
    }
}