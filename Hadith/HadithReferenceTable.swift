//
//  HadithReferenceTable.swift
//  Hadith
//
//  Created by Majid Khan on 3/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import JLToast

class HadithReferenceTable : UITableViewController {
    
    let collectionManager = CollectionManager.sharedInstance()
    var list : [String] = []
    var crossRefList : [CrossReference] = []
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "References"
        default:
            return "Cross References"
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 + (crossRefList.isEmpty ? 0 : 1)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HadithReferenceCell")
        if indexPath.section == 0 {
            cell?.textLabel?.text = list[indexPath.row]
        } else {
            cell?.textLabel?.text = crossRefList[indexPath.row].text
        }
        return cell!
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return list.count
        default:
            return crossRefList.count
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            if CopyReferenceOnTapSetting.load() == true {
                UIPasteboard.generalPasteboard().string = list[indexPath.row]
                JLToast.makeText("Copied to clipboard").show()

            }
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.selected = false
        default:
            let linkUrl = crossRefList[indexPath.row].link
            let hadith = Utils.urlToHadith(linkUrl)
            if (hadith == nil) {
                if let url = NSURL(string: linkUrl) {
                    UIApplication.sharedApplication().openURL(url)
                }
            } else {
                openHadith(hadith!)
            }
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.selected = false
        }
    }
    
    func openHadith(hadith : Hadith) {
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("HadithDetailsViewController") as! HadithDetailsViewController
        viewController.initializeFrontPage(hadith)
        navigationController?.pushViewController(viewController, animated: true)
    }
}