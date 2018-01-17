//
//  SwipeStyleViewController.swift
//  Hadith
//
//  Created by Majid Khan on 17/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit


class SwipeStyleViewController : CustomTableViewController {
    
    @IBOutlet weak var cellScroll: SwipeSettingCell!
    @IBOutlet weak var cellPage: SwipeSettingCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let setting = SwipeStyleSetting.load()
        if (setting == .Page) {
            cellPage.accessoryType = .Checkmark
        } else if (setting == .Scroll) {
            cellScroll.accessoryType = .Checkmark
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        for cell in tableView.visibleCells {
            cell.accessoryType = .None
        }
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SwipeSettingCell
        cell.selected = false
        if (cell.reuseIdentifier == "CellScroll") {
            cell.setting = .Scroll
        } else if (cell.reuseIdentifier == "CellPage") {
            cell.setting = .Page
        }
        cell.updateCheck()
        cell.setting.save()
        Analytics.logEvent(.SwipeStyleSettingChange, value: cell.reuseIdentifier!)

        
        var preferencesViewController : PreferencesViewController? = nil
        let list = (tabBarController?.viewControllers)!
        for l in list {
            for v in l.childViewControllers {
                if (v.restorationIdentifier == "PreferencesViewController") {
                    preferencesViewController = v as? PreferencesViewController
                }
            }
        }
        
        preferencesViewController?.loadSwipeStyleSetting()
        
        // Go back
        navigationController?.popViewControllerAnimated(true)
    }
}