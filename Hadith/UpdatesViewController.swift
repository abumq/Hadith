//
//  UpdatesViewController.swift
//  Hadith
//
//  Created by Majid Khan on 3/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class UpdatesViewController : CustomTableViewController {
    
    var collectionManager = CollectionManager.sharedInstance()
    var databaseManager = DatabaseManager.sharedInstance()
    var databaseUpdateManager = DatabaseUpdateManager.sharedInstance()
    var bookmarkManager = BookmarkManager.sharedInstance()
    var noteManager = NoteManager.sharedInstance()
    
    var installed : [DatabaseMetaInfo] = []
    var pendingUpdates : [DatabaseMetaInfo] = []
    var available : [DatabaseMetaInfo] = []
    var retired : [DatabaseMetaInfo] = []
    var failed : [DatabaseMetaInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let databaseMetaInfoCellNib = UINib(nibName: "DatabaseMetaInfoCell", bundle: nil)
        tableView.registerNib(databaseMetaInfoCellNib, forCellReuseIdentifier: "DatabaseMetaInfoCell")
        
        spinner.startAnimating()
        
        databaseUpdateManager.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        initCells()
        self.databaseUpdateManager.detectPausedDownloads()
        spinner.stopAnimating()
    }
    
    func initCells() {
        // Dont add spinner here because this is called very often
        pendingUpdates.removeAll()
        available.removeAll()
        retired.removeAll()
        installed.removeAll()
        failed.removeAll()
        let updates = self.databaseUpdateManager.checkForUpdates()
        // The ones available for any type of update
        for update in updates {
            switch (update.updateType) {
            case .Pending: pendingUpdates.append(update)
            case .Available: available.append(update)
            case .Retired: retired.append(update)
            case .Failed: failed.append(update)
            default: break
            }
        }
        
        // No updates
        for infoId in databaseManager.databaseMetaInfo.keys {
            let info = databaseManager.databaseMetaInfo[infoId]
            if (info?.updateType == .NoUpdate && updates.indexOf({$0.id == info?.id}) == nil) {
                installed.append(info!)
            }
        }
        self.sortList(&self.pendingUpdates)
        self.sortList(&self.available)
        self.sortList(&self.retired)
        self.sortList(&self.installed)
        self.sortList(&self.failed)
        tableView.reloadData()
    }
    
    func sortList(inout list:[DatabaseMetaInfo]) -> [DatabaseMetaInfo] {
        list = list.sort({ (databaseMetaInfo1, databaseMetaInfo2) -> Bool in
            return databaseMetaInfo1.name < databaseMetaInfo2.name
        })
        return list
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 55.0 : 70.0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0: return "Quick Actions"
        case 1: return self.pendingUpdates.isEmpty ? nil : "Pending Updates"
        case 2: return self.available.isEmpty ? nil : "Also Available"
        case 3: return self.retired.isEmpty ? nil : "Retired"
        case 4: return self.failed.isEmpty ? nil : "Failed"
        default: return self.installed.isEmpty ? nil : "Downloaded"
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let defaultSize = UITableViewAutomaticDimension
        switch (section) {
        case 0: return defaultSize
        case 1: return self.pendingUpdates.isEmpty ? 1.0 : defaultSize
        case 2: return self.available.isEmpty ? 1.0 : defaultSize
        case 3: return self.retired.isEmpty ? 1.0 : defaultSize
        case 4: return self.failed.isEmpty ? 1.0 : defaultSize
        default: return self.installed.isEmpty ? 1.0 : defaultSize
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let defaultSize = UITableViewAutomaticDimension

        switch (section) {
        case 0: return self.pendingUpdates.isEmpty && self.available.isEmpty ? defaultSize : 1.0
        case 1: return self.pendingUpdates.isEmpty ? 1.0 : defaultSize
        case 2: return self.available.isEmpty ? 1.0 : defaultSize
        case 3: return self.retired.isEmpty ? 1.0 : defaultSize
        case 4: return self.failed.isEmpty ? 1.0 : defaultSize
        default: return self.installed.isEmpty ? 1.0 : defaultSize
        }
    }
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch (section) {
        case 0: return self.pendingUpdates.isEmpty && self.available.isEmpty ? "All databases are up-to-date!" : nil
        case 1: return self.pendingUpdates.isEmpty ? nil : "Databases that need to be updated"
        case 2: return self.available.isEmpty ? nil : "Databases that you do not have yet"
        case 3: return self.retired.isEmpty ? nil : "Databases that are no longer used"
        case 4: return self.failed.isEmpty ? nil : "Please wait for new updates for these databases"
        default: return self.installed.isEmpty ? "" : "Last Checked: " + databaseUpdateManager.updateLastChecked.formatAsString()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 6
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0: return 2
        case 1: return pendingUpdates.count
        case 2: return available.count
        case 3: return retired.count
        case 4: return failed.count
        default: return installed.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var list : [DatabaseMetaInfo]? = nil
        switch (indexPath.section) {
        case 0: list = nil
        case 1: list = pendingUpdates
        case 2: list = available
        case 3: list = retired
        case 4: list = failed
        default: list = installed
        }
        if list != nil {
            let cell : DatabaseMetaInfoCell = tableView.dequeueReusableCellWithIdentifier("DatabaseMetaInfoCell") as! DatabaseMetaInfoCell
            let info : DatabaseMetaInfo? = list?[indexPath.row]
            
            // Very good for testing slow responses
            // info?.url = "http://fake-response.appspot.com/?sleep=500"
            cell.label?.text = info?.name
            cell.databaseMetaInfo = info!
            
            // First check current queue, server may be slow so we cannot rely on progressed()
            let task = databaseUpdateManager.findTaskById(cell.databaseMetaInfo.id)
            if task != nil && task!.state == .Updating {
                cell.renderAsDownloading("Updating...", taskProgress: task!.progress)
            } else if task != nil && task!.state == .Paused {
                cell.renderAsPaused(task!.progress)
            } else if info != nil {
                switch info!.updateType {
                case DatabaseMetaInfo.UpdateType.Failed:
                    cell.renderAsFailed()
                case DatabaseMetaInfo.UpdateType.NoUpdate:
                    cell.renderAsInstalled()
                default:
                    if ((cell.databaseMetaInfo.id == databaseManager.masterDatabase?.id
                        && Double(Utils.appVersion) < cell.databaseMetaInfo.requiredAppVersion)
                        || (cell.databaseMetaInfo.id == databaseManager.searchDatabase?.id
                            && Double(Utils.appVersion) < cell.databaseMetaInfo.requiredAppVersion)) {
                        cell.detailLabel?.text = "Please update your app from AppStore first"
                        cell.icon?.image = UIImage(named: "warn")
                    } else {
                        cell.renderAsReadyToDownload()
                    }
                }
            }
            return cell
        } else {
            
            // Command section
            let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("CommandCell") as UITableViewCell!
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Update All (Pending Only)"
                let noUpdates = self.pendingUpdates.isEmpty && self.failed.isEmpty
                cell.textLabel?.textColor = noUpdates ? UIColor.grayColor() : UIColor.appThemeTintColor()
                cell.accessoryType = noUpdates ? .Checkmark : .None
                var subtitle = ""
                var totalSize = 0.0
                for update in self.pendingUpdates {
                    totalSize += update.size
                }
                for update in self.failed {
                    totalSize += update.size
                }
                if totalSize > 0 {
                    subtitle = Utils.bytesToHumanReadable(totalSize)
                }
                cell.detailTextLabel?.text = subtitle
            default:
                cell.textLabel?.text = "Download All"
                let noUpdates = self.pendingUpdates.isEmpty && self.failed.isEmpty && self.available.isEmpty
                cell.textLabel?.textColor = noUpdates ? UIColor.grayColor() : UIColor.appThemeTintColor()
                cell.accessoryType = noUpdates ? .Checkmark : .None
                var subtitle = ""
                var totalSize = 0.0
                for update in self.pendingUpdates {
                    totalSize += update.size
                }
                for update in self.available {
                    totalSize += update.size
                }
                for update in self.failed {
                    totalSize += update.size
                }
                if totalSize > 0 {
                    subtitle = Utils.bytesToHumanReadable(totalSize)
                }
                cell.detailTextLabel?.text = subtitle
            }
            
            return cell
            
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != 0 {
            let cell : DatabaseMetaInfoCell = tableView.cellForRowAtIndexPath(indexPath) as!    DatabaseMetaInfoCell
            self.viewVersionDetails(cell.databaseMetaInfo)
        } else {
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            cell.selected = false

            var list = [DatabaseMetaInfo]()
            switch indexPath.row {
            case 0: // pending only
                list = self.pendingUpdates
                list.appendContentsOf(self.failed)
            default:
                list = self.pendingUpdates
                list.appendContentsOf(self.available)
                list.appendContentsOf(self.failed)
            }
            if !list.isEmpty {
                let alert = AlertViewWithCallback()
                alert.dismissWithClickedButtonIndex(1, animated: true)
                alert.title = "Updates"
                alert.message = "Download " + cell.detailTextLabel!.text! + "?"
                alert.alertViewStyle = UIAlertViewStyle.Default
                alert.addButtonWithTitle("OK")
                alert.addButtonWithTitle("Cancel")
                alert.callback = { buttonIndex in
                    if buttonIndex == 0 {
                        Analytics.logEvent(indexPath.row == 0 ? .UpdateAll : .DownloadAll)
                        for databaseMetaInfo in list {
                            self.databaseUpdateManager.start(databaseMetaInfo)
                        }
                    } else {
                        Analytics.logEvent(indexPath.row == 0 ? .UpdateAll : .DownloadAll, value: "Cancelled (Size: " + cell.detailTextLabel!.text! + ")")
                    }
                }
                alert.show()
            } else {
                self.initCells()
            }
        }
    }
    
    func viewVersionDetails(databaseMetaInfo : DatabaseMetaInfo) {
        let databaseMetaInfoViewController = storyboard?.instantiateViewControllerWithIdentifier("DatabaseMetaInfoDetailViewController") as! DatabaseMetaInfoDetailViewController
        databaseMetaInfoViewController.databaseMetaInfoId = databaseMetaInfo.id
        navigationController?.pushViewController(databaseMetaInfoViewController, animated: true)
    }
    
    func databaseMetaInfoIdToCell(id: String) -> DatabaseMetaInfoCell? {
        for cell in tableView.visibleCells {
            if cell.isKindOfClass(DatabaseMetaInfoCell.self) {
                let databaseMetaInfoCell = cell as! DatabaseMetaInfoCell
                if (databaseMetaInfoCell.databaseMetaInfo.id == id) {
                    return databaseMetaInfoCell
                }
            }
        }
        return nil
    }
    
    func cancelOrResumeUpdate(sender:UIButton) {
        if let cell = sender.superview?.superview as? DatabaseMetaInfoCell {
            let alert = UIAlertController(title: "Updates", message: "What would you like to do?", preferredStyle: UIAlertControllerStyle.Alert)
            if (self.databaseUpdateManager.isPaused(cell.databaseMetaInfo)) {
                alert.addAction(UIAlertAction(title: "Resume", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                    self.databaseUpdateManager.resume(cell.databaseMetaInfo)
                }))
            } else {
                alert.addAction(UIAlertAction(title: "Pause", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                    self.databaseUpdateManager.pause(cell.databaseMetaInfo)
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel Update", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                self.databaseUpdateManager.cancel(cell.databaseMetaInfo)
            }))
            
            alert.addAction(UIAlertAction(title: "Ignore", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func download(sender:UIButton) {
        if let cell = sender.superview?.superview as? DatabaseMetaInfoCell {
            if (cell.databaseMetaInfo.updateType != .NoUpdate) {
                var message = ""
                switch (cell.databaseMetaInfo.updateType) {
                case .Pending:
                    message = String(format: "Name: %@\nVersion: v0.%d\nDownload Size: %@", cell.databaseMetaInfo.name, cell.databaseMetaInfo.version, Utils.bytesToHumanReadable(cell.databaseMetaInfo.size))
                    
                case .Available:
                    message = String(format: "Name: %@\nVersion: v0.%d\nDownload Size: %@", cell.databaseMetaInfo.name, cell.databaseMetaInfo.version, Utils.bytesToHumanReadable(cell.databaseMetaInfo.size))
                    
                case .Retired:
                    message = String(format: "Database '%@' is no longer used. We will delete it from your device to save some space.", cell.databaseMetaInfo.name)
                    
                case .Failed:
                    message = String(format: "Name: %@\nVersion: v0.%d\nDownload Size: %@", cell.databaseMetaInfo.name, cell.databaseMetaInfo.version, Utils.bytesToHumanReadable(cell.databaseMetaInfo.size))
                    
                default: break
                }
                let alert = UIAlertController(title: "Updates", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: cell.databaseMetaInfo.updateType == .Retired ? "Remove" : "Download", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                    cell.renderAsDownloading()
                    self.databaseUpdateManager.start(cell.databaseMetaInfo)
                }))
                
                alert.addAction(UIAlertAction(title: "View Details", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                    self.viewVersionDetails(cell.databaseMetaInfo)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func queueForDeletion(sender:UIButton) {
        if let cell = sender.superview?.superview as? DatabaseMetaInfoCell {
            
            let databaseMetaInfo : DatabaseMetaInfo = cell.databaseMetaInfo
            var message = ""
            var title = ""
            if (databaseMetaInfo.updateType == .Retired) {
                message = "Are you sure you want to keep this database?"
                title = "Keep"
            } else {
                message = "Are you sure you want to remove this database?\nAll personal data (e.g, bookmarks etc.) from this database will be deleted."
                title = "Remove"
            }
            let alert = UIAlertController(title: title, message: String(format:message + "\n\nName: %@\nVersion: v0.%d\nSize: %@", databaseMetaInfo.name, databaseMetaInfo.version, Utils.bytesToHumanReadable(databaseMetaInfo.size)), preferredStyle: UIAlertControllerStyle.Alert)
            if (databaseMetaInfo.updateType == .Retired) {
                // Already queued
                alert.addAction(UIAlertAction(title: "Keep It", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                    
                    databaseMetaInfo.updateType = .NoUpdate
                    cell.renderAsInstalled()
                    self.databaseUpdateManager.cancel(databaseMetaInfo)
                }))
            } else {
                alert.addAction(UIAlertAction(title: "Remove", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                    databaseMetaInfo.updateType = .Remove
                    cell.detailLabel?.text = "Queued For Removal"
                    cell.actionButton?.setImage(UIImage(named: "delete"), forState: .Normal)
                    self.databaseUpdateManager.start(databaseMetaInfo)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "View Details", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                self.viewVersionDetails(databaseMetaInfo)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

extension UpdatesViewController : DatabaseUpdateManagerDelegate {
    
    
    func started(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.renderAsDownloading()
        } else {
            Log.write("Could not determine cell at databaseUpdateStarted")
        }
    }
    
    func completed(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.renderAsInstalled()
            
            var settingsViewController : SettingsViewController? = nil
            let list = (tabBarController?.viewControllers)!
            for l in list {
                for v in l.childViewControllers {
                    if (v.restorationIdentifier == "SettingsViewController") {
                        settingsViewController = v as? SettingsViewController
                    }
                }
            }
            settingsViewController?.badgeAndCellUpdater?.fire()
            collectionManager?.loadData()
            bookmarkManager.housekeeping()
            noteManager.housekeeping()
        } else {
            Log.write("Could not determine cell at databaseUpdateCompleted")
        }
    }
    
    func failed(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.renderAsFailed()
        } else {
            Log.write("Could not determine cell at databaseUpdateFailed")
        }
    }
    
    func progressed(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.updateProgress("Updating...", taskProgress: updateTask.progress)
        }
        // Do not log if cell fails to initialize as this function is called frequently
    }
    
    func cancelled(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.renderAsReadyToDownload()
        } else {
            Log.write("Could not determine cell at databaseUpdateCancelled")
        }
    }
    
    func paused(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.renderAsPaused(updateTask.progress)
        } else {
            Log.write("Could not determine cell at databaseUpdatePaused")
        }
    }
    
    func resumed(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.renderAsDownloading()
            cell.updateProgress("Updating...", taskProgress: updateTask.progress)
        } else {
            Log.write("Could not determine cell at databaseUpdateResumed")
        }
    }
    
    func pausedDetected(updateTask : DatabaseUpdateTask) {
        if let cell = databaseMetaInfoIdToCell(updateTask.databaseMetaInfo!.id) {
            cell.renderAsPaused(updateTask.progress)
        } else {
            Log.write("Could not determine cell at databaseUpdatePausedDetected")
        }
    }
    
    func thumbnailUpdated(databaseMetaInfo: DatabaseMetaInfo) {
        // determine cell then
        collectionManager = CollectionManager.sharedInstance()
        
        if let collection = collectionManager.getCollectionsMapWithIdentifiers()[databaseMetaInfo.id] {
            collectionManager.thumbnailUpdated(collection)
        }
    }
}