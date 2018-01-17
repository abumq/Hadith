//
//  EmptyDataInfo.swift
//  Hadith
//
//  Created by Majid Khan on 24/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation


enum EmptyDataImages : String {
    case None = "none"
    case Data = "data-grey"
    case Search = "search-grey"
    case Bookmarks = "bookmarks-grey"
    case Notes = "notes-grey"
    case Internet = "wifi"
}

enum EmptyDataDefaultType {
    case NoData
    case AppVersion
}

typealias EmptyDataInfo = (title:String, description:String, imageName:EmptyDataImages, hasButton:Bool)
