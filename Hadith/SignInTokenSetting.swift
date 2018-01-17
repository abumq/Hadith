//
//  SignInTokenSetting.swift
//  Hadith
//
//  Created by Majid Khan on 13/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class SignInTokenSetting : Setting<String> {
    
    override class func getSettingName() -> String {
        return "sign-in-token"
    }
}