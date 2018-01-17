//
//  SearchTableViewController.swift
//  Hadith
//
//  Created by Majid Khan on 31/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite
import DZNEmptyDataSet

class SearchTableViewController : TableViewControllerWithEmptyDataHandler {
    
    var searchResults : [Keyword] = [Keyword]()
    var searchController : UISearchController!
    let databaseManager = DatabaseManager.sharedInstance()
    
    var conn : Connection!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(searchResultsController: nil)
        do {
            if (databaseManager.searchDatabaseFile == nil) {
                emptyDataInfo = getDefaultEmptyData(.NoData)
                return
            }
            if (Double(Utils.appVersion) < databaseManager.searchDatabase?.requiredAppVersion) {
                emptyDataInfo = getDefaultEmptyData(.AppVersion, args: String(databaseManager.searchDatabase?.requiredAppVersion))
                return
            }
            conn = try Connection(databaseManager.searchDatabaseFile!)
            searchController.searchResultsUpdater = self
            searchController.searchBar.delegate = self
            searchController.dimsBackgroundDuringPresentation = false
            definesPresentationContext = true
            tableView.tableHeaderView = searchController.searchBar
            searchController.searchBar.placeholder = "Enter keyword or hadith reference"
            emptyDataInfo = ("Search", "Enter keyword or hadith reference and press 'Search'", .Search, false)
        } catch {
            emptyDataInfo = ("Unexpected Error", "Please check for updates in 'Settings' tab", .Search, false)
        }
    }
    
    
    deinit {
        // There seems to be bug in UISearchController
        // see http://stackoverflow.com/questions/32282401/attempting-to-load
        if let superView = searchController?.view?.superview {
            superView.removeFromSuperview()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("KeywordCell") as UITableViewCell?
        let keyword = self.searchResults[indexPath.row]
        cell?.textLabel?.text = keyword.text
        return cell!
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let rowTapped = indexPath.row
        if (self.searchResults.count > rowTapped) {
            var items = self.searchController.searchBar.text?.characters.split(" ").map(String.init)
            items?.removeLast()
            
            var finalText = (items?.joinWithSeparator(" "))!
            if !finalText.isEmpty {
                finalText.appendContentsOf(" ")
            }
            finalText.appendContentsOf(searchResults[rowTapped].text + " ")
            self.searchController.searchBar.text = finalText
            self.searchResults.removeAll()
            tableView.reloadData()
        }
    }
    
    func performAutocompleteSearch(text: String){
        self.searchResults.removeAll()
        tableView.reloadData()
        let items = text.characters.split(" ").map(String.init)
        let searchText = items.count > 0 ? items[items.count - 1] : ""
        if searchText.isEmpty {
            return
        }
        var keywordTable = Table(Keyword.TableName)
        keywordTable = keywordTable.filter(Hadith.Column.text.lowercaseString.like(searchText + "%"))
        keywordTable = keywordTable.order(Hadith.Column.text)
        keywordTable = keywordTable.limit(30, offset: 0)
        
        do {
            for k in try conn.prepare(keywordTable) {
                let keyword = Keyword().buildFromRow(k)
                searchResults.append(keyword)
            }
        } catch {
            Log.write(error)
        }
        
        tableView.reloadData()
    }
    
    func performSearch() {
        let searchQuery = searchController.searchBar.text!
        if searchQuery.isEmpty {
            return
        }
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("SearchResultsTableViewController") as! SearchResultsTableViewController
        viewController.keyword = searchQuery
        navigationController?.pushViewController(viewController, animated: true)
    }
}
extension SearchTableViewController : UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        performAutocompleteSearch(searchController.searchBar.text!)
    }
}
extension SearchTableViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }
}