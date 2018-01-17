//
//  BookViewController.swift
//  Hadith
//
//  Created by Majid Khan on 29/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import DZNEmptyDataSet

class BookViewController : HadithListViewController {
    
    var books = [Book]()
    var filteredBooks = [Book]()
    var volBooksMap = [Int:[Book]]()
    
    override func viewDidLoad() {
        
        let bookCellNib = UINib(nibName: "BookCell", bundle: nil)
        tableView.registerNib(bookCellNib, forCellReuseIdentifier: "BookCell")
        
        super.viewDidLoad()
        
    }
    
    override func loadData() {
        
        guard let db = self.databaseManager.database(self.collection.identifier) else {
            self.emptyDataInfo = ("No Data Found", "Please download to continue.", .Data, true)
            return
        }
        if (Double(Utils.appVersion) < db.requiredAppVersion) {
            self.emptyDataInfo = ("Update Your App", "Please update your app from AppStore.\nMinimum app version required: v\(db.requiredAppVersion)", .Data, false)
            return
        }
        self.spinner.startAnimating()
        self.volBooksMap = [:]
        
        // We load in pieces, first we load books (so user can at least browse books and search books)
        // When books are loaded we then load hadiths (so user can search books and all hadiths in this collection)
        ({
            let resultList = self.collectionManager.loadBookList(self.collection, emptyDataInfo: &self.emptyDataInfo)
            if self.collection.hasVolumes && !resultList.isEmpty {
                for vol in 1...resultList.last!.volumeNumber! {
                    self.volBooksMap[vol] = resultList.filter({$0.volumeNumber == vol})
                }
            }
            self.books = resultList
        }) ~> ({
            if self.books.isEmpty {
                self.emptyDataInfo = ("No Data Found", "Please download to continue.", .Data, true)
            } else {
                ({
                    let resultList = self.collectionManager.loadHadithListForBooks(self.collection, books: self.books, emptyDataInfo: &self.emptyDataInfo)
                    self.hadiths = resultList
                }) ~> ({
                    // Search is now ready incl. hadiths
                    self.tableView.reloadData()
                })
                self.emptyDataInfo = ("No Result", "No matching book found in \(self.collection.name)", .Search, false)
            }
            self.spinner.stopAnimating()
            self.tableView.reloadData()
        })
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if filtering {
            return indexPath.section == 0 ? 94.0 : super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
        return 94.0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if filtering {
            return 2
        }
        return collection.hasVolumes && !books.isEmpty ? books.last!.volumeNumber! : 1

    }
    
    override var filtering: Bool {
        get {
            return !(searchController.searchBar.text?.isEmpty)! && searchController.active
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if filtering {
            return section == 0 ? "Books" : "Hadiths"
        }
        return collection.hasVolumes && !books.isEmpty ? "Volume " + String(section + 1) : ""
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if filtering {
            if filteredBooks.isEmpty && filteredHadiths.isEmpty {
                emptyDataInfo = ("No Result", "No matching books or hadith found in \(self.collection.name)", .Search, false)
            }
            
            return section == 0 ? filteredBooks.count : filteredHadiths.count
        }
        let booksInVolume = self.volBooksMap[section + 1] != nil ? self.volBooksMap[section + 1]!.count : 0
        return booksInVolume == 0 ? books.count : booksInVolume
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if filtering {
            if indexPath.section == 0 { // Books
                let cell = tableView.dequeueReusableCellWithIdentifier("BookCell") as! BookCell
                let book = filteredBooks[indexPath.row]
                cell.titleLabel?.text = String(book.bookNumber) + ". " + book.name
                if book.lowerLimit == nil && book.upperLimit == nil {
                    cell.detailLabel?.text = (book.totalHadiths > 0 ? String(book.totalHadiths) : "No") + " Hadith" + (book.totalHadiths > 1 ? "s" : "")
                } else {
                    cell.detailLabel?.text = book.lowerLimit! + " - " + book.upperLimit! + " Hadiths";
                }
                return cell
            } else if indexPath.section == 1 { // Hadiths
                return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            }
        } else {
            // Section = Volume X
            let cell = tableView.dequeueReusableCellWithIdentifier("BookCell") as! BookCell
            let book = self.volBooksMap[indexPath.section + 1] != nil ? self.volBooksMap[indexPath.section + 1]![indexPath.row] : books[indexPath.row]
            cell.titleLabel?.text = String(book.bookNumber) + ". " + book.name
            if book.lowerLimit == nil && book.upperLimit == nil {
                cell.detailLabel?.text = (book.totalHadiths > 0 ? String(book.totalHadiths) : "No") + " Hadith" + (book.totalHadiths > 1 ? "s" : "")
            } else {
                cell.detailLabel?.text = book.lowerLimit! + " - " + book.upperLimit! + " Hadiths";
            }
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if filtering {
            if indexPath.section == 0 {
                let book = filteredBooks[indexPath.row]
                showHadithListViewController(book)
            } else if indexPath.section == 1 {
                let hadith = filteredHadiths[indexPath.row]
                super.book = hadith.book
                super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
            }
        } else {
            let book = self.volBooksMap[indexPath.section + 1] != nil ? self.volBooksMap[indexPath.section + 1]![indexPath.row] : books[indexPath.row]
            showHadithListViewController(book)
        }
    }
    
    private func showHadithListViewController(book : Book) {
        let viewController = (storyboard?.instantiateViewControllerWithIdentifier("HadithListViewController") as? HadithListViewController!)!
        viewController.collection = collection
        viewController.book = book
        Analytics.logEvent(.OpenBook, value: book.name)
        if (navigationController?.visibleViewController?.restorationIdentifier != viewController.restorationIdentifier) {
            navigationController?.pushViewController(viewController, animated: true)
            
            if searchController.searchBar.text?.isEmpty == true {
                searchController.active = false
                searchController.searchBar.selectedScopeButtonIndex = 0
            }
        }
    }
    
    func performBookFilter(text: String, scope: String) -> [Book] {
        return books.filter { book in
            var result = book.name.lowercaseString.containsString(text.lowercaseString)
                || String(book.bookNumber).containsString(text.lowercaseString)
            if book.volumeNumber != nil {
                result = result || String(book.volumeNumber).containsString(text.lowercaseString)
            }
            return result
        }
    }
    
    override func performFilterInBackground() {
        // First filter books because it will be fast
        var resultList = [Book]()
        BackgroundWorker.sharedInstance().startAfter(0.3, task: {
            resultList = self.performBookFilter(self.searchController.searchBar.text!, scope: self.searchScope)
        }, completion: {
            self.filteredBooks = resultList
            self.tableView.reloadData()
        })
        super.performFilterInBackground()
    }
}