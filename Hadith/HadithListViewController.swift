//
//  HadithListViewController.swift
//  Hadith
//
//  Created by Majid Khan on 30/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import DZNEmptyDataSet

class HadithListViewController : TableViewControllerWithEmptyDataHandler {
    
    var searchController : UISearchController!
    let collectionManager = CollectionManager.sharedInstance()
    let databaseManager = DatabaseManager.sharedInstance()
    var collection : Collection!
    var book : Book!
    var hadiths = [Hadith]()
    var filteredHadiths = [Hadith]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hadithCellNib = UINib(nibName: "HadithCell", bundle: nil)
        tableView.registerNib(hadithCellNib, forCellReuseIdentifier: "HadithCell")
        
        let hadithSearchCellNib = UINib(nibName: "HadithSearchResultCell", bundle: nil)
        tableView.registerNib(hadithSearchCellNib, forCellReuseIdentifier: "HadithSearchResultCell")
        
        
        
        self.title = self.getTitle()
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.placeholder = "Search"
        if book != nil || collection != nil {
            searchController.searchBar.placeholder = searchController.searchBar.placeholder! + (book != nil ? " Book of " + book!.name : " " + collection.name)
        }
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = ["All", "Authentic Only"]
        tableView.tableHeaderView = searchController.searchBar
        
        loadData()
    }
    
    func getTitle() -> String {
        return book == nil ? collection.name : book.name
    }
    
    func loadData() {
        tableView.separatorStyle = .None
        self.spinner.startAnimating()
        ({
            if self.book != nil {
                let resultList = self.collectionManager.loadHadithListForBooks(self.collection, books: [self.book], emptyDataInfo: &self.emptyDataInfo)
                self.hadiths = resultList

            } else {
                let resultList = self.collectionManager.loadHadithListForCollection(self.collection, emptyDataInfo: &self.emptyDataInfo)
                self.hadiths = resultList

            }
        }) ~> ({
            if self.hadiths.isEmpty {
                self.emptyDataInfo = ("No Data Found", "Please download to continue.", .Data, true)
            } else {
                if self.collection.hasBooks {
                    self.emptyDataInfo = ("No Result", "No matching hadith found in Book of \(self.book.name) in \(self.collection.name)", .Search, false)
                } else {
                    self.emptyDataInfo = ("No Result", "No matching hadith found in \(self.collection.name)", .Search, false)
                }
            }
            self.spinner.stopAnimating()
            self.tableView.reloadData()
        })
        
    }
    
    
    var filtering : Bool {
        get {
            var result = searchController.active
            if self.searchScope == "All" {
                result = result && !searchController.searchBar.text!.isEmpty
            }
            return result
        }
    }
    
    var searchScope : String {
        get {
            return searchController.searchBar.scopeButtonTitles![searchController.searchBar.selectedScopeButtonIndex]
        }
    }
    
    deinit {
        // There seems to be bug in UISearchController
        // see http://stackoverflow.com/questions/32282401/attempting-to-load
        if let superView = searchController?.view?.superview {
            superView.removeFromSuperview()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.filtering ? 145.0 : 90.0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filtering {
            if filteredHadiths.isEmpty {
                if self.collection.hasBooks {
                    self.emptyDataInfo = ("No Result", "No matching hadith found in Book of \(self.book.name) in \(self.collection.name)", .Search, false)
                } else {
                    self.emptyDataInfo = ("No Result", "No matching hadith found in \(self.collection.name)", .Search, false)
                }
            }
            return filteredHadiths.count
        }
        return hadiths.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let hadith : Hadith!
        if self.filtering {
            hadith = filteredHadiths[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("HadithSearchResultCell") as! HadithSearchResultCell

            cell.refsLabel.text = ""
            var ref = hadith.getRef(.SecondaryRef)
            if (ref != nil) {
                cell.refsLabel.text = ref
            }
            ref = hadith.getRef(.VolumeOnly)
            if (ref != nil) {
                cell.refsLabel.text = cell.refsLabel.text! + "\n" + ref!
            }
            ref = hadith.getRef(.VolumeAndBook)
            if (ref != nil) {
                cell.refsLabel.text = cell.refsLabel.text! + "\n" + ref!
            }
            if cell.refsLabel.text?.isEmpty == true {
                cell.refsLabel.text = hadith.availableRef
            }
            
            cell.render(hadith, highlightText: searchController.searchBar.text!)
            return cell
        } else {
            hadith = hadiths[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("HadithCell") as! HadithCell
            cell.render(hadith, highlightText: searchController.searchBar.text!)
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("HadithDetailsViewController") as! HadithDetailsViewController
        let hadith : Hadith!
        if self.filtering {
            hadith = filteredHadiths[indexPath.row]
            // Don't set hadiths and index here and let view controller figure it out
        } else {
            hadith = hadiths[indexPath.row]
            viewController.index = indexPath.row
            viewController.hadiths = hadiths
        }
        viewController.initializeFrontPage(hadith)
        if (navigationController?.visibleViewController?.restorationIdentifier != viewController.restorationIdentifier) {
            navigationController?.pushViewController(viewController, animated: true)
            
            if searchController.searchBar.text?.isEmpty == true {
                searchController.active = false
                searchController.searchBar.selectedScopeButtonIndex = 0
            }
        }
    }
    
    func performFilter(searchString: String, scope : String = "All") -> [Hadith] {
        var resultList = hadiths.filter { hadith in
            var result = hadith.hadithNumber.lowercaseString.containsString(searchString.lowercaseString)
            result = result || hadith.text.lowercaseString.containsString(searchString.lowercaseString)
            if hadith.tags != nil {
                result = result || hadith.tags!.lowercaseString.containsString(searchString.lowercaseString)
            }
            if hadith.refTags != nil {
                result = result || hadith.refTags!.lowercaseString.containsString(searchString.lowercaseString)
            }
            if hadith.bookNumber != nil {
                let str = String(hadith.bookNumber!) + "/" + hadith.hadithNumber
                result = result || str.containsString(searchString.lowercaseString)
            }
            if hadith.volumeNumber != nil {
                let str = String(hadith.volumeNumber!) + "/" + hadith.hadithNumber
                result = result || str.containsString(searchString.lowercaseString)
            }
            
            if scope == "Authentic Only" {
                if searchString.isEmpty {
                    result = hadith.hadithGrades.contains { hadithGrade in
                        return HadithGrade.AuthenticList.contains(hadithGrade.flag)
                    }
                } else {
                    result = result && hadith.hadithGrades.contains { hadithGrade in
                        return HadithGrade.AuthenticList.contains(hadithGrade.flag)
                    }
                }
            }
            return result
        }
        
        // exact match found or not we also search for by words
        let list = searchString.characters.split{$0 == " "}.map(String.init)
        if list.count <= 1 {
            return resultList
        }
        resultList.appendContentsOf(hadiths.filter { hadith in
            if !resultList.isEmpty && resultList.contains(hadith) {
                // We do not want duplicates
                return false
            }
            let subjectString = hadith.text
            var hadithHasAllSearchWords = true
            for word in list {
                if subjectString.lowercaseString.indexOf(word.lowercaseString) == -1 {
                    hadithHasAllSearchWords = false
                    break
                }
            }
            if hadithHasAllSearchWords {
                for word in list {
                    let pos = subjectString.lowercaseString.indexOf(word)
                    if (pos > -1) {
                        if (pos > 50) {
                            hadith.customText = "..." + subjectString.substringFrom(pos - 50)
                        } else {
                            hadith.customText = nil
                        }
                        // break at first occurance of word
                        // for example if search term is "three men" and subject is "two or three or four men"
                        // then we pos at occurance of "three" - 50
                        return true
                    }
                }
                return false
            }
            return hadithHasAllSearchWords
        })
        
        resultList = resultList.sort({ (hadith1, hadith2) -> Bool in
            return hadith1.volumeNumber < hadith2.volumeNumber
                && hadith1.bookNumber < hadith2.bookNumber
        })
        return resultList
    }
    
    func performFilterInBackground() {
        // Because we are performing this in background we only want to upgrade the 
        // filteredHadith model only after backgroundWorker has finished the task
        // otherwise we can run in to indexOutOfBound in cellForRowAtIndexPath
        var resultList = [Hadith]()
        BackgroundWorker.sharedInstance().startAfter(0.3, task: {
            resultList = self.performFilter(self.searchController.searchBar.text!, scope: self.searchScope)
        }, completion: {
            self.filteredHadiths = resultList
            self.tableView.reloadData()
        })
    }
}

extension HadithListViewController : UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.performFilterInBackground()
    }
}

extension HadithListViewController : UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.performFilterInBackground()
    }
}