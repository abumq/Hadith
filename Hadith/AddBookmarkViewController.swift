//
//  AddBookmarkViewController.swift
//  Hadith
//
//  Created by Majid Khan on 3/08/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import JLToast

class AddBookmarkViewController : BookmarksViewController {
        
    var parent : AddBookmarkParentViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        parent.replaceWith(bookmarkManager.bookmarks[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}