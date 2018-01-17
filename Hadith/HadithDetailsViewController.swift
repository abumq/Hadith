//
//  HadithDetailsViewController.swift
//  Hadith
//
//  Created by Majid Khan on 26/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import JLToast

class HadithDetailsViewController : CustomViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, HadithPageDelegate {
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var scrollView : UIScrollView!
    
    // Maximum number of hadith pages to load
    let maxPagesPerBatch = 10
    
    // currentPage should always be initialized by the presenter of this view controller
    // this should be done using initializeFrontPage(...) function
    // hence this is private
    private var currentPage : HadithPage!
    
    var pageController : UIPageViewController!
    var pages = [Int:HadithPage]()
    
    var bookmarkManager = BookmarkManager.sharedInstance()
    var databaseManager = DatabaseManager.sharedInstance()
    var collectionManager = CollectionManager.sharedInstance()
    var noteManager = NoteManager.sharedInstance()
    
    var nextIndex : Int = 0
    var index : Int = 0
    var hadiths : [Hadith] = []
    var addBookmarkButton : UIBarButtonItem!
    var writeNoteButton : UIBarButtonItem!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.startAnimating()
        let transitionStyle : UIPageViewControllerTransitionStyle = SwipeStyleSetting.load() == SwipeStyleSetting.Page ? .PageCurl : .Scroll
        pageController = UIPageViewController(transitionStyle: transitionStyle, navigationOrientation: .Horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        
        self.addChildViewController(pageController)
        scrollView.addSubview(pageController.view)
        pageController.view.frame = scrollView.frame
        
        // Render bookmark button
        self.addBookmarkButton = UIBarButtonItem(image: UIImage(named: "bookmark-empty"), style: .Plain, target: self, action: #selector(self.addOrRemoveBookmark))
        self.bookmarkManager.delegates[self.restorationIdentifier!] = self
        
        self.writeNoteButton = UIBarButtonItem(image: UIImage(named: "write-note"), style: .Plain, target: self, action: #selector(self.writeNote))
        self.noteManager.delegates[self.restorationIdentifier!] = self
        
        self.navigationItem.rightBarButtonItems = [self.addBookmarkButton, self.writeNoteButton]
        self.updateButtons()

        // Render first page
        self.pages[self.index] = self.currentPage
        self.pageController.setViewControllers([self.pages[self.index]!], direction: .Forward, animated: false, completion: nil)
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(showToolbar), userInfo: nil, repeats: false)
        spinner.stopAnimating()
        loadData()
        
    }
    
    func initializeFrontPage(hadith: Hadith) {
        currentPage = initHadithPage()
        currentPage.currentHadith = hadith
        if let hadithByLanguages = self.collectionManager.loadHadithAndLanguages(currentPage.currentHadith) {
            currentPage.currentHadithByLanguages = hadithByLanguages
        }
        currentPage.delegate = self
        currentPage.index = self.index
    }
    
    func UIChanged() {
        // Don't update bookmarks button here as this is called even when it's "being" flipped
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let currentPage = viewController as! HadithPage
        
        if let index = currentPage.index {
            self.index = index
            nextIndex = index - 1
            let page = pages[nextIndex]
            let isIndexMultiple = nextIndex % maxPagesPerBatch == 0
            if pages.count < hadiths.count && isIndexMultiple {
                self.loadSiblingPagesBackward(index)
            } else if pages.count < hadiths.count && page == nil {
                // This should never happen unless flipping way too fast
                Log.write("Destination page was nil, trying to load at index %d", index)
                self.loadSiblingPagesBackward(index)
            }
            
            return page
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let currentPage = viewController as! HadithPage

        if let index = currentPage.index {
            self.index = index
            nextIndex = index + 1
            let page = pages[nextIndex]
            
            let isIndexMultiple = nextIndex % maxPagesPerBatch == 0
            if pages.count < hadiths.count && index > 0 && isIndexMultiple {
                self.loadSiblingPagesForward(nextIndex)
            } else if pages.count < hadiths.count && index > 0 && page == nil {
                // This should never happen unless flipping way too fast
                Log.write("Destination page was nil, trying to load at index %d", index)
                self.loadSiblingPagesForward(index)
            }
            return page
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed && index != nextIndex {
            self.currentPage = self.pages[nextIndex]
            if self.currentPage != nil {
                self.index = self.currentPage.index!
                nextIndex = index
                self.currentPage.associatedNote = self.noteManager.getNote(self.currentPage.defaultHadith)
                self.currentPage.updateUI()
                self.updateButtons()
                
                if self.currentPage.index == 0 {
                    JLToast.makeText("Beginning of the " + (currentPage.currentHadith.collection!.hasBooks ? "book" : "collection")).show()
                } else if self.currentPage.index == self.hadiths.count - 1 {
                    JLToast.makeText("End of the " + (currentPage.currentHadith.collection!.hasBooks ? "book" : "collection")).show()
                }
            }
        }
    }

    
    func showToolbar() {
        self.toolbar.hidden=false
    }
    
    private func initHadithPage() -> HadithPage {
        return storyboard?.instantiateViewControllerWithIdentifier("HadithPage") as! HadithPage
    }
    
    func loadData() {
        self.spinner.startAnimating()
        var hadithAndLanguages : HadithByLanguage? = nil
        ({
            hadithAndLanguages = self.collectionManager.loadHadithAndLanguages(self.currentPage.currentHadith)
        }) ~> ({
            if hadithAndLanguages != nil {
                self.currentPage.currentHadithByLanguages = hadithAndLanguages!
                self.currentPage.associatedNote = self.noteManager.getNote(self.currentPage.defaultHadith)
                self.currentPage.hadithByLanguagesUpdated()
            }

            // Load siblings if needed
            if (self.hadiths.isEmpty == true) {
                self.hadiths.append(self.currentPage.currentHadith!)
                self.loadSiblingHadiths()
            } else {
                self.pages.removeAll()
                self.loadSiblingPagesBackward(self.index)
                self.loadSiblingPagesForward(self.index)
            }
            self.spinner.stopAnimating()
        })
    }
    
    private func loadSiblingPages(from:Int, to: Int) {
        let toFixed = max(0, min(to, self.hadiths.count))
        let fromFixed = max(0, min(toFixed, from))
        var idx = fromFixed
        for hadith in self.hadiths[fromFixed..<toFixed] {
            let page = self.initHadithPage()
            page.currentHadith = hadith
            if let hadithByLanguage = self.collectionManager.loadHadithAndLanguages(hadith) {
                page.currentHadithByLanguages = hadithByLanguage
                page.index = idx
                self.pages[idx] = page
                idx += 1
            }
            page.delegate = self
        }
       Log.write("Loaded %d to %d", fromFixed, toFixed)

    }
    
    private func loadSiblingPagesBackward(fromIndex : Int = 0) {
        ({
            self.loadSiblingPages(fromIndex - self.maxPagesPerBatch, to: fromIndex)
        }) ~> ({
        })
    }
    
    private func loadSiblingPagesForward(fromIndex : Int = 0) {
        ({
            self.loadSiblingPages(fromIndex, to: fromIndex + 1 + self.maxPagesPerBatch)
        }) ~> ({
        })
    }
    
    //
    // Loads list of hadith from same book as currentHadith
    // also sets currentIndex and then enables next buttons
    //
    // this is done in background
    //
    private func loadSiblingHadiths() {
        ({
            let siblings = self.collectionManager.loadSiblings(self.currentPage.currentHadith)
            if (siblings != nil) {
                //
                self.pages[self.index]?.index = siblings!.index
                self.index = siblings!.index
                self.hadiths = siblings!.hadithList
            }
        }) ~> ({
            self.loadSiblingPagesBackward(self.index)
            self.loadSiblingPagesForward(self.index)
        })
    }
    
    func updateButtons() {
        if self.currentPage != nil && bookmarkManager.isBookmarked(self.currentPage.defaultHadith) {
            addBookmarkButton.image = UIImage(named:"bookmark-filled")
        } else {
            addBookmarkButton.image = UIImage(named:"bookmark-empty")
        }
        if self.currentPage != nil && noteManager.hasNote(self.currentPage.defaultHadith) {
            writeNoteButton.image = UIImage(named:"write-note-filled")
        } else {
            writeNoteButton.image = UIImage(named:"write-note")
        }
    }
    
    @IBAction func showActions(sender: UIBarButtonItem) {
        if let hadithLink = NSURL(string: self.currentPage.currentHadith.hadithLink) {
            let availableRef = self.currentPage.currentHadith.availableRef
            var grade = ""
            for i in 0...self.currentPage.currentHadith.hadithGrades.count - 1 {
                grade += self.currentPage.currentHadith.hadithGrades[i].text
                if i < self.currentPage.currentHadith.hadithGrades.count - 1 {
                    grade += ", "
                }
            }
            let textToShare = self.currentPage.currentHadith.nonHTMLText + " \n\n[" + availableRef + " (" + grade + ")]\n"
            let objectsToShare = [textToShare, hadithLink]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: [CopyUrlActivity(url: hadithLink)])
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    @objc func addOrRemoveBookmark() {
        if bookmarkManager.isBookmarked(self.currentPage.defaultHadith) {
            let alert = AlertViewWithCallback()
            alert.dismissWithClickedButtonIndex(1, animated: true)
            alert.title = "Do you want to remove this bookmark?"
            alert.alertViewStyle = UIAlertViewStyle.Default
            alert.addButtonWithTitle("Remove")
            alert.callback = { buttonIndex in
                if buttonIndex == 0 {
                    self.bookmarkManager.remove([self.currentPage.defaultHadith])
                }
            }
            alert.addButtonWithTitle("Cancel")
            alert.show()
        } else {
            let viewController = storyboard?.instantiateViewControllerWithIdentifier("AddBookmarkParentViewController") as! AddBookmarkParentViewController
            viewController.refHadith = self.currentPage.defaultHadith
            let navController = UINavigationController.init(rootViewController: viewController)
            navController.title = "Add Bookmark"
            self.presentViewController(navController, animated: true, completion: nil);
        }
    }
    
    @objc func writeNote() {
        if currentPage != nil {
            let viewController = storyboard?.instantiateViewControllerWithIdentifier("WriteNoteViewController") as! WriteNoteViewController
            viewController.hadith = currentPage.defaultHadith
            viewController.note = currentPage.associatedNote
            let navController = UINavigationController.init(rootViewController: viewController)
            if currentPage.associatedNote != nil {
                navController.title = "Edit Note"
            } else {
                navController.title = "Write Note"
            }
            self.presentViewController(navController, animated: true, completion: nil)
        } else {
            JLToast.makeText("Unexpected error, go back and retry").show()
        }
    }
    
}
extension HadithDetailsViewController : NoteManagerDelegate {
    func notesLoaded() {
        currentPage.associatedNote = noteManager.getNote(currentPage.defaultHadith)
        currentPage.updateUI()
        self.updateButtons()
    }
    
    func noteAddFailed(message : String) {
        let alert = UIAlertView()
        alert.dismissWithClickedButtonIndex(0, animated: true)
        alert.title = message
        alert.alertViewStyle = UIAlertViewStyle.Default
        alert.addButtonWithTitle("OK")
        alert.show()
    }
}
extension HadithDetailsViewController : BookmarkManagerDelegate {
    func bookmarksLoaded() {
        self.updateButtons()
    }
    
    func bookmarkAddFailed(message : String) {
        let alert = UIAlertView()
        alert.dismissWithClickedButtonIndex(0, animated: true)
        alert.title = message
        alert.alertViewStyle = UIAlertViewStyle.Default
        alert.addButtonWithTitle("OK")
        alert.show()
    }
}