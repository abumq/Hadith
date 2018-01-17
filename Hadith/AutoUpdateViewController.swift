//
//  AutoUpdateViewController.swift
//  Hadith
//
//  Created by Majid Khan on 6/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit


class AutoUpdateViewController : CustomTableViewController {
    
    @IBOutlet weak var cellWiFiCellular: AutoUpdateSettingCell!
    @IBOutlet weak var cellWiFi: AutoUpdateSettingCell!
    @IBOutlet weak var cellNever: AutoUpdateSettingCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let setting = AutoUpdateSetting.load()
        if (setting == .Never) {
            cellNever.accessoryType = .Checkmark
        } else if (setting == .WiFi) {
            cellWiFi.accessoryType = .Checkmark
        } else if (setting == .WiFiCellular) {
            cellWiFiCellular.accessoryType = .Checkmark
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        for cell in tableView.visibleCells {
            cell.accessoryType = .None
        }
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! AutoUpdateSettingCell
        if (cell.reuseIdentifier == "CellNever") {
            cell.setting = .Never
        } else if (cell.reuseIdentifier == "CellWiFi") {
            cell.setting = .WiFi
        } else if (cell.reuseIdentifier == "CellWiFiCellular") {
            cell.setting = .WiFiCellular
        }
        Analytics.logEvent(.AutoUpdateSettingChange, value: cell.reuseIdentifier!)
            
        cell.updateCheck()
        cell.setting.save()
        
        
        var settingsViewController : SettingsViewController? = nil
        let list = (tabBarController?.viewControllers)!
        for l in list {
            for v in l.childViewControllers {
                if (v.restorationIdentifier == "SettingsViewController") {
                    settingsViewController = v as? SettingsViewController
                }
            }
        }
        
        settingsViewController?.loadAutoUpdateSetting()
        
        // Go back
        navigationController?.popViewControllerAnimated(true)
    }
}