//
//  DatabaseUpdateTask.swift
//  Hadith
//
//  Created by Majid Khan on 26/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
enum DatabaseUpdateState {
    case Updating
    case Paused
    case NotUpdating
}
class DatabaseUpdateTask : NSObject {
    var databaseMetaInfo : DatabaseMetaInfo?
    var state : DatabaseUpdateState = .NotUpdating
    var progress : Float = 0.0
    var resumeData : NSData?
    var task : NSURLSessionDownloadTask?
    
    init(databaseMetaInfo : DatabaseMetaInfo) {
        self.databaseMetaInfo = databaseMetaInfo
    }
}