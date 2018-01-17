//
//  SearchResultsTableViewController.swift
//  Hadith
//
//  Created by Majid Khan on 8/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import DZNEmptyDataSet

class SearchResultsTableViewController : HadithListViewController, SearchFooterDelegate {
    
    var keyword : String = ""
    var options : Int = 0
    private var searchKeyword : String = ""
    private var pageNumber = 1
    private var totalPages = -1
    private var totalCount = 0
    private var collections : [Int:Collection] = [:]
    private var languageOffsets : [Int:[Int:Int]] = [:]
    
    private var searchResultsPerPage = SearchResultsPerPageSetting.getDefault()!
    
    @IBOutlet weak var headerView : SearchHeaderView!
    @IBOutlet weak var footerView : SearchFooterView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let hadithSearchCellNib = UINib(nibName: "HadithSearchResultCell", bundle: nil)
        tableView.registerNib(hadithSearchCellNib, forCellReuseIdentifier: "HadithSearchResultCell")
        searchResultsPerPage = SearchResultsPerPageSetting.load()!

        footerView.delegate = self
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
        collections = collectionManager.getCollectionsMapWithIds()
        Analytics.logEvent(Analytics.EventType.AdvancedSearch, value: searchKeyword)
        self.performSearch(false, resetPageNumbersMap: true)
        
        
    }
    
    override func getTitle() -> String {
        return "Search Results"
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 145.0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hadiths.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : HadithSearchResultCell = tableView.dequeueReusableCellWithIdentifier("HadithSearchResultCell") as! HadithSearchResultCell
        let hadith = hadiths[indexPath.row]
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
        cell.render(hadith, highlightText: self.keyword)
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let hadith = hadiths[indexPath.row]
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("HadithDetailsViewController") as! HadithDetailsViewController
        viewController.initializeFrontPage(hadith)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func nextPage() {
        if pageNumber >= totalPages {
            return
        }
        pageNumber = pageNumber + 1
        performSearch()
    }
    func prevPage() {
        if pageNumber <= 1 {
            return
        }
        pageNumber = pageNumber - 1
        performSearch()
    }
    func firstPage() {
        if pageNumber <= 1 {
            return
        }
        pageNumber = 1
        performSearch()
    }
    
    private func prepareKeyword() -> String {
        var finalKeyword = self.keyword
        let terms = Set(finalKeyword.characters.split(" ").map(String.init)).reverse()
        finalKeyword = terms.joinWithSeparator(" ")
        return finalKeyword
    }
    
    override func loadData(){
    }
    
    private func performSearch(scrollToTop : Bool = true, resetPageNumbersMap : Bool = false) {
        self.spinner.startAnimating()
        self.spinner.updateSpinnerLabel("Searching...")
        self.hadiths.removeAll()
        self.tableView.reloadData()
        self.headerView.hidden = true
        self.footerView.hidden = true
        self.keyword = self.keyword.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        ({
            self.searchKeyword = self.prepareKeyword()
            
            Log.write("Searching [%@]", self.searchKeyword)
            
            if self.searchKeyword.characters.count <= 1 {
                self.emptyDataInfo = ("No Result", "Search could not find hadith", .Search, false)
                
                return
            }
            if resetPageNumbersMap || self.languageOffsets.count < self.collectionManager.languages.count {
                for collection in self.collectionManager.collections {
                    for language in self.collectionManager.languages[collection.id]! {
                        self.languageOffsets[language.id] = [:]
                        self.languageOffsets[language.id]![self.pageNumber] = 0
                    }
                }
            }
            for collection in self.collectionManager.collections {
                for language in self.collectionManager.languages[collection.id]! {
                    let newOffset = self.hadiths.count >= self.searchResultsPerPage ? 0 : self.searchLanguage(language, searchTerm: self.searchKeyword)
                    let offsetForPage = self.languageOffsets[language.id]![self.pageNumber]!
                    self.languageOffsets[language.id]![self.pageNumber + 1] = offsetForPage + newOffset
                    // Note: do not break here as we want offsets for next page to be 0 if displaying max allowed results
                }
            }
            if self.totalPages == -1 {
                if (self.hadiths.count < self.searchResultsPerPage) {
                    self.totalCount = self.hadiths.count
                    self.totalPages =  1
                } else {
                    for collection in self.collectionManager.collections {
                        for language in self.collectionManager.languages[collection.id]! {
                            let count = self.countActual(language, searchTerm: self.searchKeyword)
                            self.totalCount += count
                        }
                    }
                    self.totalPages =  Int(ceil(CGFloat(self.totalCount) / CGFloat(self.searchResultsPerPage)))
                }
            }
            
        }) ~> ({
            
            
            self.footerView.prevPageButton.enabled = self.totalPages > 1 && self.pageNumber > 1
            self.footerView.firstPageButton.enabled = self.totalPages > 1 && self.pageNumber > 1
            self.footerView.nextPageButton.enabled = self.totalPages > 1 && self.pageNumber < self.totalPages
            // TODO: add to search history (settings)
            
            if self.totalCount == 0 {
                self.emptyDataInfo = ("No Result", String(format: "No result found for '%@'. Try again with simple terms.", self.keyword), .Search, false)
                self.headerView.resultsCountLabel.text = ""
                self.footerView.hidden = true
            } else {
                self.headerView.hidden = false
                self.headerView.resultsCountLabel.text = String(format: "%d result\(self.totalCount > 1 ? "s" : "") found for '%@'", self.totalCount, self.keyword)
                if self.totalCount > self.searchResultsPerPage {
                    self.footerView.hidden = false
                    self.headerView.pageDetailsLabel.text = String(format: "Displaying %d on page %d / %d", self.hadiths.count, self.pageNumber, self.totalPages)
                } else {
                    self.headerView.pageDetailsLabel.text = ""
                }
            }
            self.spinner.stopAnimating()
            self.tableView.reloadData()
            if scrollToTop {
                self.tableView.contentOffset = CGPointZero
            }
        })
    }
    
    private func buildFilter(searchTerm : String) -> Table? {
        var hadithTable = Table(Hadith.TableName)
        
        var list = searchTerm.lowercaseString.characters.split{$0 == " "}.map(String.init)
        list = list.filter({ term in
            return term.characters.count > 2
        })
        if list.isEmpty {
            return nil
        }
        for word in list {
            let term = "%" + word + "%"
            let filterExpressionText = Hadith.Column.text.lowercaseString.like(term)
            let filterExpressionTag = Hadith.Column.tags.lowercaseString.like(term)
            let filterExpressionRef = Hadith.Column.refTags.lowercaseString.like(term)
            hadithTable = hadithTable.filter(filterExpressionText || filterExpressionTag || filterExpressionRef)
        }
        //Log.debug("SQL: " + hadithTable.asSQL()) // - Crashes
        return hadithTable
    }
    
    private func searchLanguage(language: Language, searchTerm : String) -> Int {
        if searchTerm.isEmpty {
            return 0
        }
        var newOffset = 0
        do {
            let conn = try Connection(databaseManager.databaseFile(language.identifier)!)
            let collection = collections[language.collectionNumber]
            if collection == nil {
                Log.write("Collection [\(language.collectionNumber)] is null for language \(language.name)")
                return 0
            }
            var hadithTable = self.buildFilter(searchTerm)
            if hadithTable == nil {
                return 0
            }
            let offsetMapByLang = self.languageOffsets[language.id]!
            let offsetByPage = offsetMapByLang[self.pageNumber]!
            let offset = Int(offsetByPage)
            hadithTable = hadithTable!.order([Hadith.Column.volumeNumber, Hadith.Column.bookNumber])
            Log.write("Lang: \(language.id) [\(language.name) \(collection!.name)] page=\(pageNumber) offset=\(offset)")
            let limit = self.searchResultsPerPage - hadiths.count
            hadithTable = hadithTable!.limit(limit, offset: offset)
            do {
                for h in try conn.prepare(hadithTable!) {
                    let hadith = Hadith().buildFromRow(h)
                    hadith.collection = collection
                    if collection!.hasBooks {
                        var bookTable = Table(Book.TableName)
                        bookTable = bookTable.filter(Book.Column.collectionNumber == collection!.id)
                        bookTable = bookTable.filter(Book.Column.bookNumber == hadith.bookNumber!)
                        for b in try conn.prepare(bookTable) {
                            let book = Book().buildFromRow(b)
                            book.collection = collection
                            hadith.book = book
                        }
                    }
                    newOffset += 1
                    hadiths.append(hadith)
                }
            } catch {
                Log.write("Error at %d (Lang: %@)", collection!.id, language.name)
                Log.write(error)
            }
            
        } catch {
            Log.write(error)
            return 0
        }
        return newOffset
    }
    
    func countActual(language: Language, searchTerm : String) -> Int {
        if searchTerm.isEmpty {
            return 0
        }
        do {
            let conn = try Connection(databaseManager.databaseFile(language.identifier)!)
            let hadithTable = buildFilter(searchTerm)
            if hadithTable == nil {
                return 0
            }
            return conn.scalar(hadithTable!.count)
            
        } catch {
            emptyDataInfo = ("Data Corrupted", "Please check updates to continue.", .Data, true)
            Log.write(error)
        }
        return 0
    }
}