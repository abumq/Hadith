//
//  AccountManagerDelegate.swift
//  Hadith
//
//  Created by Majid Khan on 13/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

@objc protocol AccountManagerDelegate : NSObjectProtocol {
    optional func accountUpdated(responseMessage:String)
    optional func tokenUpdated()
}