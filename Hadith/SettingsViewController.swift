//
//  SettingsViewController.swift
//  Hadith
//
//  Created by Majid Khan on 1/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController : CustomTableViewController, AccountManagerDelegate {
    
    private var accountManager = AccountManager.sharedInstance()
    
    @IBOutlet weak var autoUpdateCell: UITableViewCell!
    @IBOutlet var checkUpdatesCell: UITableViewCell!
    @IBOutlet var signOutCell : UITableViewCell!
    
    let databaseUpdateManager = DatabaseUpdateManager.sharedInstance()
    var badgeAndCellUpdater : NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Once we are here we no longer need MainViewController's checker
        let mainViewController = (tabBarController as! MainViewController)
        mainViewController.badgeUpdater?.invalidate()
        mainViewController.badgeUpdater = nil
        
        if (databaseUpdateManager.delegate == nil) {
            databaseUpdateManager.delegate = mainViewController
        }
        
        self.badgeAndCellUpdater = NSTimer.scheduledTimerWithTimeInterval(DatabaseUpdateManager.badgeUpdateFreq, target: self, selector: #selector(SettingsViewController.updateBadgeAndCell), userInfo: nil, repeats: true)
        self.badgeAndCellUpdater!.fire()
        loadAutoUpdateSetting()
        accountManager.delegates[self.restorationIdentifier!] = self
        self.accountUpdated("")
    }
    
    func loadAutoUpdateSetting() {
        let autoUpdateSetting = AutoUpdateSetting.load()
        switch (autoUpdateSetting) {
        case .Never:
            autoUpdateCell.detailTextLabel?.text = "Never"
        case .WiFi:
            autoUpdateCell.detailTextLabel?.text = "Wi-Fi"
        case .WiFiCellular:
            autoUpdateCell.detailTextLabel?.text = "Wi-Fi and Cellular"
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        var url : NSURL? = nil
        if (cell?.reuseIdentifier == "DonateCell") {
            url = NSURL(string: "https://paypal.me/MuflihunDotCom/25")!
        } else if (cell?.reuseIdentifier == "HelpCell") {
            url = NSURL(string: "http://muflihun.com/apps/hadith/")!
        } else if (cell?.reuseIdentifier == "FacebookCell") {
            url = NSURL(string: "https://www.facebook.com/MuflihunDotCom/")!
        } else if (cell?.reuseIdentifier == "TwitterCell") {
            url = NSURL(string: "https://twitter.com/MuflihunDotCom/")!
        } else if (cell?.reuseIdentifier == "SignOutCell" && accountManager.isLoggedIn) {
            let alert = AlertViewWithCallback()
            alert.dismissWithClickedButtonIndex(1, animated: true)
            alert.title = "Are you sure you wish to sign out?"
            alert.alertViewStyle = UIAlertViewStyle.Default
            alert.addButtonWithTitle("Sign Out")
            alert.addButtonWithTitle("Cancel")
            alert.callback = { buttonIndex in
                if buttonIndex == 0 {
                    self.accountManager.signOut()
                }
            }
            alert.show()
        }
        
        if url != nil {
            UIApplication.sharedApplication().openURL(url!)
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1:
            return accountManager.isLoggedIn ? accountManager.loggedInMessage : nil
        default:
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Preferences
        case 1: return accountManager.isLoggedIn ? 2 : 1 // Sign in
        case 2: return 2 // Updates
        case 3: return 2 // Social
        case 4: return 3 // About & Help
        default: return 0
        }
    }
    
    func accountUpdated(responseMessage: String) {
        signOutCell.selectionStyle = accountManager.isLoggedIn ? UITableViewCellSelectionStyle.Blue : UITableViewCellSelectionStyle.None
        signOutCell.textLabel?.textColor = accountManager.isLoggedIn ? UIColor.redColor() : UIColor.grayColor()
        tableView.reloadData()
    }
    
    func updateBadgeAndCell() {
        let updates = databaseUpdateManager.checkForUpdates()
        var updatesCount = 0
        for update in updates {
            if (update.updateType == .Pending) {
                updatesCount += 1
            }
        }
        if (updatesCount > 0) {
            tabBarController?.tabBar.items!.last!.badgeValue = String(updatesCount)
            checkUpdatesCell?.detailTextLabel?.text = String(format: "%d Update" + (updatesCount > 1 ? "s" : ""), updatesCount)
            databaseUpdateManager.startAutoUpdateIfPossible()
        } else {
            tabBarController?.tabBar.items!.last!.badgeValue = nil
            checkUpdatesCell?.detailTextLabel?.text = "No Updates"
        }
        // Following check is only needed here (in SettingsViewController) because this is pathway to get to
        // updates, without getting here there is no way to get to UpdatesViewController anyway
        if let updatesViewController = navigationController?.visibleViewController as? UpdatesViewController {
            updatesViewController.initCells()
        }
    }
}
