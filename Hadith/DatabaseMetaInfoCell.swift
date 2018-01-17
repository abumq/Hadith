//
//  SettingsCellCheckForUpdates.swift
//  Hadith
//
//  Created by Majid Khan on 3/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
class DatabaseMetaInfoCell : CustomTableViewCell {
    @IBOutlet weak var label : UILabel?
    @IBOutlet weak var detailLabel : UILabel?
    @IBOutlet var icon: UIImageView!
    @IBOutlet weak var progress: KDCircularProgress?
    
    @IBOutlet weak var actionButton: UIButton?
    @IBOutlet weak var progressLabel: UILabel?
    
    var databaseMetaInfo : DatabaseMetaInfo = DatabaseMetaInfo()
    
    func renderAsPaused(taskProgress : Float) {
        updateIcon()
        let angle = (taskProgress / 100) * 360
        let perc = taskProgress
        let decimalPoint = perc == 0 || perc == 100 ? "0" : "1"
        progressLabel?.text? = String(format: "%." + decimalPoint + "f%%", perc)
        progress?.angle = Double(angle)
        progress?.hidden = false
        detailLabel?.text = "Paused"
        actionButton?.setImage(UIImage(named: self.databaseMetaInfo.updateType == .Retired ? "delete-green" : "download"), forState: .Normal)
        setAction(#selector(UpdatesViewController.cancelOrResumeUpdate(_:)))
    }
    
    func updateProgress(message : String, taskProgress : Float) {
        let angle = (taskProgress / 100) * 360
        let perc = taskProgress
        progress?.angle = Double(angle)
        let decimalPoint = perc == 0 || perc == 100 ? "0" : "1"
        progressLabel?.text? = String(format: "%." + decimalPoint + "f%%", perc)
        if (progress?.hidden == true) {
            // UI was destroyed? Re-initiate
            progress?.hidden = false
            setAction(#selector(UpdatesViewController.cancelOrResumeUpdate(_:)))
            actionButton?.setImage(UIImage(named: "delete"), forState: .Normal)
            actionButton?.hidden = false
        }
        detailLabel?.text = message
    }
    
    func renderAsDownloading(message : String? = nil, taskProgress : Float = 0.0) {
        updateIcon()
        var queuedMessage = message
        if queuedMessage == nil {
            switch (databaseMetaInfo.updateType) {
            case .Pending, .Available, .Failed:
                queuedMessage = String(format: "Queued (%@)", Utils.bytesToHumanReadable(databaseMetaInfo.size))
            case .Retired:
                queuedMessage = String(format: "Queued")
            default: queuedMessage = ""
            }
        }
        setAction(#selector(UpdatesViewController.cancelOrResumeUpdate(_:)))
        actionButton?.setImage(UIImage(named: "delete"), forState: .Normal)
        actionButton?.hidden = false
        updateProgress(queuedMessage!, taskProgress: taskProgress)
    }
    
    func updateIcon() {
        switch (databaseMetaInfo.updateType) {
        case .Pending:
            icon?.image = UIImage(named: "update_db")
        case .Available:
            icon?.image = UIImage(named: "add_db")
        case .Retired:
            icon?.image = UIImage(named: "remove_db")
        case .Failed:
            icon?.image = UIImage(named: "failed-db")
        default: // No Update
            icon?.image = UIImage(named: "check")
        }
    }
    
    func renderAsFailed() {
        updateIcon()
        renderAsReadyToDownload()
        detailLabel?.text = "Failed, please see details"
        self.progress?.hidden = true
        progress?.angle = 0
        progressLabel?.text? = "0%"
    }
    
    func renderAsReadyToDownload() {
        updateIcon()
        self.detailLabel?.text = String(format: "Update Available v0.%d (%@)", self.databaseMetaInfo.version, Utils.bytesToHumanReadable(self.databaseMetaInfo.size))
        self.setAction(#selector(UpdatesViewController.download(_:)))
        self.actionButton?.setImage(UIImage(named: self.databaseMetaInfo.updateType == .Retired ? "delete-green" : "download"), forState: .Normal)
        self.actionButton?.hidden = false
        self.progress?.hidden = true
        progress?.angle = 0
        progressLabel?.text? = "0%"
    }
    
    func renderAsInstalled() {
        updateIcon()
        self.detailLabel?.text = String(format: "v0.%d (%@)" + (self.databaseMetaInfo.requiredAppVersion != Double(Utils.appVersion) ? " (Requires App Version v%.1f or above)" : ""), self.databaseMetaInfo.version, Utils.bytesToHumanReadable(self.databaseMetaInfo.size), self.databaseMetaInfo.requiredAppVersion)
        self.actionButton?.hidden = true
        self.progress?.hidden = true
        if (self.databaseMetaInfo.id != DatabaseManager.sharedInstance().masterDatabase?.id
            && self.databaseMetaInfo.id != DatabaseManager.sharedInstance().searchDatabase?.id) {
            self.setAction(#selector(UpdatesViewController.queueForDeletion(_:)))
            self.actionButton?.setImage(UIImage(named: "trash"), forState: .Normal)
            self.actionButton?.hidden = false
        }
        if (self.databaseMetaInfo.updateType == .Retired) {
            self.actionButton?.hidden = true
            self.icon?.image = UIImage(named: "warn")
            self.detailLabel?.text = "Removed"
            self.detailLabel?.textColor = UIColor.lightGrayColor()
            self.label?.textColor = UIColor.lightGrayColor()
        }
    }
    
    func setAction(action:Selector) {
        self.actionButton?.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
        self.actionButton?.addTarget(nil, action: action, forControlEvents: .TouchUpInside)
    }
}