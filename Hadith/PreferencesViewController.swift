//
//  PreferencesViewController.swift
//  Hadith
//
//  Created by Majid Khan on 5/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit


class PreferencesViewController : CustomTableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var swipeStyleCell: UITableViewCell!
    @IBOutlet var copyRefOnTapSwitch : UISwitch!
    @IBOutlet var autoSyncNotes : UISwitch!
    @IBOutlet var autoSyncBookmarks : UISwitch!
    @IBOutlet var searchResultsPerPageStepper : UIStepper!
    @IBOutlet var searchResultsPerPageLabel : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSwipeStyleSetting()
        copyRefOnTapSwitch.setOn(CopyReferenceOnTapSetting.load() == true, animated: false)
        autoSyncNotes.setOn(AutoSyncNotes.load() == true, animated: false)
        autoSyncBookmarks.setOn(AutoSyncBookmarks.load() == true, animated: false)
        searchResultsPerPageStepper.value = Double(SearchResultsPerPageSetting.load()!)
        searchResultsPerPageUpdated(self.searchResultsPerPageStepper)
    }
    
    func loadSwipeStyleSetting() {
        let setting = SwipeStyleSetting.load()
        switch (setting) {
        case .Page:
            swipeStyleCell.detailTextLabel?.text = "Page"
        case .Scroll:
            swipeStyleCell.detailTextLabel?.text = "Scroll"
        }
    }
    
    @IBAction func updateCopyRefOnTap(sender: UISwitch) {
        CopyReferenceOnTapSetting.save(sender.on)
    }
    
    @IBAction func updateAutoSyncNotes(sender: UISwitch) {
        AutoSyncNotes.save(sender.on)
    }
    
    @IBAction func updateAutoSyncBookmarks(sender: UISwitch) {
        AutoSyncBookmarks.save(sender.on)
    }
    
    @IBAction func searchResultsPerPageUpdated(sender: UIStepper) {
        SearchResultsPerPageSetting.save(Int(sender.value))
        searchResultsPerPageLabel.text = String(Int(sender.value))
        Analytics.logEvent(.SearchResultsPerPageSettingChange, value: searchResultsPerPageLabel.text!)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
    }
}