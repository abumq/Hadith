//
//  SearchResultsPerPageSetting.swift
//  Hadith
//
//  Created by Majid Khan on 16/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class SearchResultsPerPageSetting : Setting<Int> {
    
    override class func getDefault() -> Int? {
        return 30
    }
    
    override class func getSettingName() -> String {
        return "search-results-per-page"
    }
}