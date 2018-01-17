//
//  CollectionManagerDelegate.swift
//  Hadith
//
//  Created by Majid Khan on 17/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation


@objc protocol CollectionManagerDelegate : NSObjectProtocol {
    optional func dataLoaded(emptyDataTitle:String, emptyDataDescription:String)
    optional func thumbnailUpdated(identifier:String)
}