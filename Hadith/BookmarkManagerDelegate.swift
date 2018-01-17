//
//  BookmarkManagerDelegate.swift
//  Hadith
//
//  Created by Majid Khan on 16/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation


@objc protocol BookmarkManagerDelegate : NSObjectProtocol {
    optional func bookmarksLoaded()
    optional func bookmarkAddFailed(message : String)
    optional func syncFailed(message : String)
    optional func syncCompleted()
}