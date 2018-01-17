//
//  BookmarksViewController.swift
//  Hadith
//
//  Created by Majid Khan on 14/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import JLToast

class BookmarksViewController : HadithListViewController {
    
    let bookmarkManager = BookmarkManager.sharedInstance()
    let accountManager = AccountManager.sharedInstance()

    var collections : [Int:Collection] = [:]
    
    var filteredBookmarks : [Bookmark] = []
    var syncButton : UIBarButtonItem!
    var sortButton : UIBarButtonItem!
    
    
    override func viewDidLoad() {
        emptyDataInfo = ("No Bookmarks Found", "You can add bookmarks while reading a hadith.", .Bookmarks, false)
        
        let hadithCellNib = UINib(nibName: "HadithCell", bundle: nil)
        tableView.registerNib(hadithCellNib, forCellReuseIdentifier: "HadithCell")
        
        self.syncButton = UIBarButtonItem(image: UIImage(named: "sync"), style: .Plain, target: self, action: #selector(self.sync))
        self.sortButton = UIBarButtonItem(image: UIImage(named: "sort-desc"), style: .Plain, target: self, action: #selector(self.changeSortOrder(_:)))
       
        self.navigationItem.leftBarButtonItems = [self.syncButton]
        self.navigationItem.rightBarButtonItems = [self.sortButton]
        
        self.bookmarkManager.delegates[self.restorationIdentifier!] = self
        super.viewDidLoad()

    }
    
    override func getTitle() -> String {
        return "Bookmarks"
    }
    
    override func loadData() {
        hadiths.removeAll()
        if bookmarkManager.bookmarks.isEmpty {
            emptyDataInfo = ("No Bookmarks Added", "You can add bookmarks while reading a hadith.", .Bookmarks, false)
        } else {
            collectionManager.loadData()
            self.collections = collectionManager.getCollectionsMapWithIds()
            var removeList = [Bookmark]()
            
            for bookmark in bookmarkManager.bookmarks {
                if let collection = self.collections[bookmark.collectionId] {
                    if let hadith = collectionManager.loadHadith(collection, volumeNumber: bookmark.volumeNumber, bookNumber: bookmark.bookNumber, hadithNumber: bookmark.hadithNumber) {
                        if hadith.tags == nil {
                            hadith.tags = bookmark.name
                        } else {
                            hadith.tags! += "," + bookmark.name
                        }
                        hadiths.append(hadith)
                    } else {
                        // Hadith was removed from database
                        removeList.append(bookmark)
                    }
                } else {
                    // Collection was removed from database
                    removeList.append(bookmark)
                }
            }
            
            bookmarkManager.remove(removeList)
            
        }
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering {
            if filteredHadiths.isEmpty {
                emptyDataInfo = ("No Result", "No matching bookmark found in the list.", .Search, false)
            }
            return filteredHadiths.count
        }
        if hadiths.isEmpty {
            emptyDataInfo = ("No Bookmarks Added", "You can add bookmarks while reading a hadith.", .Bookmarks, false)
        }
        return hadiths.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! HadithCell
        let list = filtering ? filteredBookmarks : bookmarkManager.bookmarks
        let bookmark = list[indexPath.row]
        cell.titleLabel?.text = bookmark.name
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let hadith : Hadith!
        if filtering {
            hadith = filteredHadiths[indexPath.row]
        } else {
            hadith = hadiths[indexPath.row]
        }
        
        let viewController = (storyboard?.instantiateViewControllerWithIdentifier("HadithDetailsViewController") as? HadithDetailsViewController)!
        viewController.initializeFrontPage(hadith)
        navigationController?.pushViewController(viewController, animated: true)
        
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let hadith : Hadith!
        if filtering {
            hadith = filteredHadiths[indexPath.row]
        } else {
            hadith = hadiths[indexPath.row]
        }
        // Do not add alert view here
        bookmarkManager.remove([hadith])
        Analytics.logEvent(.RemoveBookmark, value: hadith.availableRef)
    }
    
    
    @IBAction func changeSortOrder(sender: UIBarButtonItem) {
        bookmarkManager.switchSortOrder()
        if bookmarkManager.sortOrder == .Latest {
            sender.image = UIImage(named: "sort-asc")
        } else {
            sender.image = UIImage(named: "sort-desc")
        }
    }
    
    override func performFilter(searchString: String, scope : String = "All") -> [Hadith] {
        let list = super.performFilter(searchString, scope: scope)
        filteredBookmarks = bookmarkManager.bookmarks.filter({ bookmark -> Bool in
            return list.contains({bookmark.matches($0)})
        })
        return list
    }
    
    func sync() {
        if self.bookmarkManager.syncing {
            JLToast.makeText("Sync in progress...").show()
            return
        }
        let loggedIn = accountManager.isLoggedIn
        let alert = AlertViewWithCallback()
        alert.dismissWithClickedButtonIndex(1, animated: true)
        if loggedIn {
            alert.title = "Sync"
            alert.message = "Are you sure you wish to sync your bookmarks?"
        } else {
            alert.title = "Sign In"
            alert.message = "Please sign-in to sync your bookmarks"
        }
        alert.alertViewStyle = UIAlertViewStyle.Default
        alert.addButtonWithTitle(loggedIn ? "Sync" : "Sign In")
        alert.addButtonWithTitle("Cancel")
        alert.callback = { buttonIndex in
            if buttonIndex == 0 {
                if loggedIn {
                    self.bookmarkManager.sync()
                    Analytics.logEvent(.SyncBookmarks)
                } else {
                    let viewController = self.storyboard?.instantiateViewControllerWithIdentifier("SignInViewController") as! SignInViewController
                    self.navigationController?.pushViewController(viewController, animated: true)
                }

            }
        }
        alert.show()
    }
    
    func refresh() {
        bookmarkManager.loadData()
    }
}

extension BookmarksViewController : BookmarkManagerDelegate {
    func bookmarksLoaded() {
        self.loadData()
    }
    
    func bookmarkAddFailed(message: String) {
        JLToast.makeText(message).show()
    }
    
    func syncCompleted() {
        bookmarkManager.loadData()
        JLToast.makeText("Sync completed").show()
    }
    
    func syncFailed(message: String) {
        JLToast.makeText(message).show()
    }
}