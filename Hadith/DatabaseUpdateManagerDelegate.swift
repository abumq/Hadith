//
//  DatabaseUpdateManagerDelegate.swift
//  Hadith
//
//  Created by Majid Khan on 3/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

@objc protocol DatabaseUpdateManagerDelegate : NSObjectProtocol {
    
    optional func started(updateTask : DatabaseUpdateTask)
    
    optional func progressed(updateTask : DatabaseUpdateTask)
    
    optional func completed(updateTask : DatabaseUpdateTask)
    
    optional func failed(updateTask : DatabaseUpdateTask)
    
    optional func paused(updateTask : DatabaseUpdateTask)
    
    optional func pausedDetected(updateTask : DatabaseUpdateTask)
    
    optional func resumed(updateTask : DatabaseUpdateTask)
    
    optional func cancelled(updateTask : DatabaseUpdateTask)
    
    optional func thumbnailUpdated(databaseMetaInfo : DatabaseMetaInfo)

}
