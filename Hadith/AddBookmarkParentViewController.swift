//
//  AddBookmarkParentViewController.swift
//  Hadith
//
//  Created by Majid Khan on 3/08/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import JLToast

class AddBookmarkParentViewController : CustomViewController {
    
    let bookmarkManager = BookmarkManager.sharedInstance()
    
    @IBOutlet weak var addBookmarkViewContainer: UIView!
    
    var refHadith : Hadith!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "AddBookmarkEmbed") {
            let viewController = segue.destinationViewController as! AddBookmarkViewController
            viewController.parent = self
        }
    }
    
    func replaceWith(bookmark:Bookmark) {
        let title = bookmark.name
        bookmarkManager.remove([bookmark])
        bookmarkManager.addBookmark(title, hadith: self.refHadith)
        Analytics.logEvent(.ReplaceBookmark, value: self.refHadith.availableRef)
        self.cancel()
        JLToast.makeText("Bookmark replaced").show()
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func add() {
        let alert = AlertViewWithCallback()
        alert.dismissWithClickedButtonIndex(1, animated: true)
        alert.title = "Enter bookmark name"
        alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        alert.addButtonWithTitle("Add")
        let textField = alert.textFieldAtIndex(0)
        textField?.placeholder = self.refHadith.availableRef
        
        alert.callback = { buttonIndex in
            if buttonIndex == 0 {
                self.bookmarkManager.addBookmark(alert.textFieldAtIndex(0)!.text!, hadith: self.refHadith)
                Analytics.logEvent(.AddBookmark, value: self.refHadith.availableRef)
                self.cancel()
                JLToast.makeText("Bookmark added").show()
            }
        }
        
        alert.addButtonWithTitle("Cancel")
        alert.show()
    }

}