//
//  Analytics.swift
//  Hadith
//
//  Created by Majid Khan on 25/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import Crashlytics

class Analytics {

    private static let enabled = true
    
    enum EventType : String {
        case OpenCollection
        case OpenBook
        case AddBookmark
        case ReplaceBookmark
        case RemoveBookmark
        case AddNote
        case SyncNotes
        case SyncBookmarks
        case SignOut
        case SignIn
        case DownloadAll
        case UpdateAll
        case AdvancedSearch
        case AutoUpdateSettingChange
        case SwipeStyleSettingChange
        case SearchResultsPerPageSettingChange
    }
    
    class func logEvent(eventType : EventType, value : String = "") {
        if !Analytics.enabled {
            return
        }
        Answers.logCustomEventWithName(eventType.rawValue, customAttributes: ["value" : value])
    }
}