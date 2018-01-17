//
//  MainViewController.swift
//  Hadith
//
//  Created by Majid Khan on 3/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class MainViewController : UITabBarController {
    
    var collectionManager = CollectionManager.sharedInstance()
    var databaseUpdateManager = DatabaseUpdateManager.sharedInstance()
    var bookmarkManager = BookmarkManager.sharedInstance()
    var noteManager = NoteManager.sharedInstance()
    var badgeUpdater : NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.badgeUpdater = NSTimer.scheduledTimerWithTimeInterval(DatabaseUpdateManager.badgeUpdateFreq, target: self, selector: #selector(MainViewController.updateUpdatesBadgeValue), userInfo: nil, repeats: true)
        self.badgeUpdater!.fire()
    }
    
    func countUpdates() -> Int {
        let updates = databaseUpdateManager.checkForUpdates()
        var updatesCount = 0
        for update in updates {
            if (update.updateType == .Pending) {
                updatesCount += 1
            }
        }
        return updatesCount
    }
    
    func updateUpdatesBadgeValue() -> Int {
        let updatesCount = self.countUpdates()
        tabBar.items?.last?.badgeValue = updatesCount > 0 ? String(updatesCount) : nil
        return updatesCount
    }
}

extension MainViewController : DatabaseUpdateManagerDelegate {
    
    func completed(updateTask : DatabaseUpdateTask) {
        let updatesCount = self.countUpdates()
       Log.write("Auto-update for [\(updateTask.databaseMetaInfo!.id)] completed - \(updatesCount) update(s) left")
        if (updatesCount == 0) {
            var settingsViewController : SettingsViewController? = nil
            let list = (self.viewControllers)!
            for l in list {
                for v in l.childViewControllers {
                    if (v.restorationIdentifier == "SettingsViewController") {
                        settingsViewController = v as? SettingsViewController
                    }
                }
            }
            self.updateUpdatesBadgeValue()
            settingsViewController?.badgeAndCellUpdater?.fire()
            collectionManager?.loadData()
            bookmarkManager.housekeeping()
            noteManager.housekeeping()
        }
    }
    
    func thumbnailUpdated(databaseMetaInfo: DatabaseMetaInfo) {
        // determine cell then
        if let collection = collectionManager.getCollectionsMapWithIdentifiers()[databaseMetaInfo.id] {
            collectionManager.thumbnailUpdated(collection)
        }
    }
}