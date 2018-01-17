//
//  DatabaseMetaInfoDetailViewController.swift
//  Hadith
//
//  Created by Majid Khan on 4/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import DZNEmptyDataSet

class DatabaseMetaInfoDetailViewController : TableViewControllerWithEmptyDataHandler {
    
    private struct Info {
        var name : String
        var detail : String
    }
    
    @IBOutlet var segmentView: UIView!
    
    var databaseMetaInfoId : String = ""
    var databaseUpdateManager = DatabaseUpdateManager.sharedInstance()
    var databaseManager = DatabaseManager.sharedInstance()
    
    private let unavailableMessageLocal = "You do not have this database downloaded."
    private let unavailableMessageRemote = "This database is retired."
    private let unavailableMessageInternet = "Please connect to the internet."
     private let unavailableMessageDownloading = "Please go back to check the progress."
    private var localDatabaseMetaInfo : DatabaseMetaInfo?
    private var remoteDatabaseMetaInfo : DatabaseMetaInfo?
    private var infoMap : [Int : Info] = [:]
    private var reachability: Reachability!
    private var state : DatabaseUpdateState? = .NotUpdating
    private var isFailed = false
    
    override func viewDidLoad() {
        emptyDataInfo = ("No Data Found", unavailableMessageLocal, .Data, true)
        super.viewDidLoad()
        
        let databaseMetaInfoDetailsCellNib = UINib(nibName: "DatabaseMetaInfoDetailsCell", bundle: nil)
        tableView.registerNib(databaseMetaInfoDetailsCellNib, forCellReuseIdentifier: "DatabaseMetaInfoDetailsCell")
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.remoteDatabaseMetaInfo = databaseUpdateManager.remoteDatabaseMetaInfo[databaseMetaInfoId]
        self.localDatabaseMetaInfo = databaseManager.databaseMetaInfo[databaseMetaInfoId]
        
        self.segmentView.bounds.size.height = navigationController!.navigationBar.bounds.size.height
        tableView.tableHeaderView = self.segmentView
        
        if (self.remoteDatabaseMetaInfo != nil) {
            self.state = databaseUpdateManager.findStateById(self.remoteDatabaseMetaInfo!.id)
            isFailed = self.remoteDatabaseMetaInfo!.updateType == .Failed
        }
        
        renderUnavailableLocalMessage()
        
        self.loadInfo(localDatabaseMetaInfo)
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            Log.write("Unable to create Reachability")
            return
        }
    }
    
    func renderUnavailableLocalMessage() {
        if self.state == .Updating || self.state == .Paused {
            emptyDataInfo.title = "Downloading..."
            if self.state == .Paused {
                emptyDataInfo.title += "(Paused)"
            }
            emptyDataInfo.description = unavailableMessageDownloading
            emptyDataInfo.hasButton = false
        } else if isFailed {
            emptyDataInfo.title = "Failed"
            emptyDataInfo.description = "Database update failed. Please wait for a new update"
            emptyDataInfo.hasButton = false
        } else {
            emptyDataInfo.description = self.unavailableMessageLocal
        }
    }
    
    func renderUnavailableRemoteMessage() {
        if !reachability.isReachable() {
            emptyDataInfo.title = "Cannot Connect"
            emptyDataInfo.description = unavailableMessageInternet
            emptyDataInfo.hasButton = false
            emptyDataInfo.imageName = .Internet
        } else {
            emptyDataInfo.description = self.unavailableMessageRemote
        }
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        emptyDataInfo.hasButton = true
        emptyDataInfo.imageName = .Data
        switch sender.selectedSegmentIndex
        {
        case 0:
            renderUnavailableLocalMessage()
            self.loadInfo(self.localDatabaseMetaInfo)
        case 1:
            renderUnavailableRemoteMessage()
            self.loadInfo(self.remoteDatabaseMetaInfo)
        default:
            break;
        }
    }
    
    func loadInfo(infoP: DatabaseMetaInfo?) {
        infoMap.removeAll()
        if (infoP != nil) {
            let info = infoP!
            var i = 0
            infoMap[i] = Info(name: "Name", detail: info.name)
            i+=1
            infoMap[i] = Info(name: "Version", detail: String(format: "v0.%d", info.version))
            i+=1
            infoMap[i] = Info(name: "Requires App Version", detail: String(format: "v%.1f or above", info.requiredAppVersion))
            i+=1
            infoMap[i] = Info(name: "Compatible With Your App", detail: Double(Utils.appVersion) == info.requiredAppVersion ? "Yes ✔" : "No, you are running app v\(Utils.appVersion). Please update your app from AppStore ✖")
            i+=1
            infoMap[i] = Info(name: "Download Size", detail: String(format: "%@", Utils.bytesToHumanReadable(info.size)))
            if (localDatabaseMetaInfo != nil) {
                let localFilename = info.databaseFile
                let fm = NSFileManager.defaultManager()
                if (!fm.fileExistsAtPath(localFilename)) {
                    i+=1
                    infoMap[i] = Info(name: "Status", detail: "Failed, please wait for new updates")
                }
            }
            i+=1
            infoMap[i] = Info(name: "Details", detail: info.details)
        }
        tableView.reloadData()
        tableView.separatorStyle = .None
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 400.0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoMap.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : DatabaseMetaInfoDetailsCell = tableView.dequeueReusableCellWithIdentifier("DatabaseMetaInfoDetailsCell", forIndexPath: indexPath) as! DatabaseMetaInfoDetailsCell
        cell.title?.text = infoMap[indexPath.row]?.name
        cell.detailLabel?.text = infoMap[indexPath.row]?.detail
        return cell
    }
    
    
    override func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        if (remoteDatabaseMetaInfo != nil && localDatabaseMetaInfo == nil) {
            databaseUpdateManager.start(remoteDatabaseMetaInfo!)
        } else if (remoteDatabaseMetaInfo == nil && localDatabaseMetaInfo != nil) {
            databaseUpdateManager.start(localDatabaseMetaInfo!)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        if emptyDataInfo.hasButton {
            var attr = [String : NSObject]()
            attr[NSForegroundColorAttributeName] = UIColor.appThemeColorLight()
            attr[NSFontAttributeName] = UIFont.boldSystemFontOfSize(17.0)
            if (remoteDatabaseMetaInfo != nil && localDatabaseMetaInfo == nil) {
                return NSAttributedString(string: "Download Now", attributes: attr)
            } else if (remoteDatabaseMetaInfo == nil && localDatabaseMetaInfo != nil) {
                return NSAttributedString(string: "Remove", attributes: attr)
            }
        }
        return NSAttributedString()
    }
}