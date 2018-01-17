//
//  NotesViewController.swift
//  Hadith
//
//  Created by Majid Khan on 6/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import JLToast

class NotesViewController : HadithListViewController {
    
    let noteManager = NoteManager.sharedInstance()
    let accountManager = AccountManager.sharedInstance()
    var collections : [Int:Collection] = [:]
    var filteredNotes : [Note] = []
    
    var syncButton : UIBarButtonItem!
    var sortButton : UIBarButtonItem!

    override func viewDidLoad() {
        emptyDataInfo = ("No Notes Found", "You can add notes while reading a hadith.", .Notes, false)
        
        let noteCellNib = UINib(nibName: "NoteCell", bundle: nil)
        tableView.registerNib(noteCellNib, forCellReuseIdentifier: "NoteCell")
        self.noteManager.delegates[self.restorationIdentifier!] = self
        
        self.syncButton = UIBarButtonItem(image: UIImage(named: "sync"), style: .Plain, target: self, action: #selector(self.sync))
        self.sortButton = UIBarButtonItem(image: UIImage(named: "sort-desc"), style: .Plain, target: self, action: #selector(self.changeSortOrder(_:)))
        
    
        self.navigationItem.leftBarButtonItems = [self.syncButton]
        self.navigationItem.rightBarButtonItems = [self.sortButton]
        
        super.viewDidLoad()
        searchController.searchBar.scopeButtonTitles = nil

    }
    
    override func getTitle() -> String {
        return "Notes"
    }
    
    override func loadData() {
        hadiths.removeAll()

        if noteManager.notes.isEmpty {
            emptyDataInfo = ("No Notes Added", "You can add notes while reading a hadith.", .Notes, false)
        } else {
            self.collections = collectionManager.getCollectionsMapWithIds()
            var removeList = [Note]()
            
            for note in noteManager.notes {
                if let collection = self.collections[note.collectionId] {
                    if let hadith = collectionManager.loadHadith(collection, volumeNumber: note.volumeNumber, bookNumber: note.bookNumber, hadithNumber: note.hadithNumber) {
                        if hadith.tags == nil {
                            hadith.tags = note.title
                        } else {
                            hadith.tags! += "," + note.title
                        }
                        hadith.text += "\n" + note.text
                        hadiths.append(hadith)
                    } else {
                        // Hadith was removed from database
                        removeList.append(note)
                    }
                } else {
                    // Collection was removed from database
                    removeList.append(note)
                }
            }
            noteManager.remove(removeList)
            
        }
        tableView.reloadData()
    }
    
    override var searchScope : String {
        get {
            return "All"
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering {
            if filteredHadiths.isEmpty {
                emptyDataInfo = ("No Result", "No matching note found in the list.", .Search, false)
            }
            return filteredHadiths.count
        }
        if hadiths.isEmpty {
            emptyDataInfo = ("No Note Added", "You can add notes while reading a hadith.", .Notes, false)
        }
        return hadiths.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NoteCell") as! NoteCell
        let list = filtering ? filteredNotes : noteManager.notes
        let note = list[indexPath.row]
        cell.titleLabel!.text = note.title
        cell.excerptLabel!.text = note.excerptText;
        if note.hadith != nil {
            cell.excerptLabel!.text! += "\n" + note.hadith!.availableRef
        }
        
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 123.0
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let alert = AlertViewWithCallback()
        alert.dismissWithClickedButtonIndex(1, animated: true)
        alert.title = "Do you want to delete this note?"
        alert.alertViewStyle = UIAlertViewStyle.Default
        alert.addButtonWithTitle("Delete")
        alert.callback = { buttonIndex in
            if buttonIndex == 0 {
                let note = self.noteManager.notes[indexPath.row]
                self.noteManager.remove([note])
            } else {
                self.tableView.editing = false
            }
        }
        alert.addButtonWithTitle("Cancel")
        alert.show()
    }
    
    
    @IBAction func changeSortOrder(sender: UIBarButtonItem) {
        noteManager.switchSortOrder()
        if noteManager.sortOrder == .Latest {
            sender.image = UIImage(named: "sort-asc")
        } else {
            sender.image = UIImage(named: "sort-desc")
        }
    }
    
    override func performFilter(searchString: String, scope : String = "All") -> [Hadith] {
        let list = super.performFilter(searchString, scope: scope)
        filteredNotes = noteManager.notes.filter({ note -> Bool in
            return list.contains({note.matches($0)})
        })
        return list
    }
    
    func sync() {
        if self.noteManager.syncing {
            JLToast.makeText("Sync in progress...").show()
            return
        }
        let loggedIn = accountManager.isLoggedIn
        let alert = AlertViewWithCallback()
        alert.dismissWithClickedButtonIndex(1, animated: true)
        if loggedIn {
            alert.title = "Sync"
            alert.message = "Are you sure you wish to sync your notes?"
        } else {
            alert.title = "Sign In"
            alert.message = "Please sign-in to sync your notes"
        }
        alert.alertViewStyle = UIAlertViewStyle.Default
        alert.addButtonWithTitle(loggedIn ? "Sync" : "Sign In")
        alert.addButtonWithTitle("Cancel")
        alert.callback = { buttonIndex in
            if buttonIndex == 0 {
                if loggedIn {
                    self.noteManager.sync()
                    Analytics.logEvent(.SyncNotes)
                } else {
                    let viewController = self.storyboard?.instantiateViewControllerWithIdentifier("SignInViewController") as! SignInViewController
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
        alert.show()
    }
    
    func refresh() {
        noteManager.loadData()
    }
}


extension NotesViewController : NoteManagerDelegate {
    func notesLoaded() {
        self.loadData()
    }
    
    func notesAddFailed(message: String) {
        JLToast.makeText(message).show()
    }
    
    func syncCompleted() {
        noteManager.loadData()
        JLToast.makeText("Sync completed").show()
    }
    
    func syncFailed(message: String) {
        JLToast.makeText(message).show()
    }
}