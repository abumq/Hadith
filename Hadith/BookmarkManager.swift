//
//  BookmarkManager.swift
//  Hadith
//
//  Created by Majid Khan on 16/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class BookmarkManager {
    
    let maxLimit = 500
    
    var collectionManager = CollectionManager.sharedInstance()
    var databaseManager = DatabaseManager.sharedInstance()
    var bookmarks = [Bookmark]()
    var delegates : [String:BookmarkManagerDelegate] = [:]
    var sortOrder = SortOrder.Oldest
    
    private var _syncing : Bool = false
    var syncing : Bool {
        get {
            return _syncing;
        }
    }
    private lazy var syncSession : NSURLSession = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.allowsCellularAccess = true
        return NSURLSession(configuration: config, delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
    }()
    
    enum SortOrder {
        case Latest
        case Oldest
    }
    
    required init() {
        self.loadData()
    }
    
    func loadData() {
        bookmarks = []
        do {
            let conn : Connection? = try Connection(databaseManager.userDataDatabaseFile)
            var bookmarkTable = Table(Bookmark.TableName)
            
            if sortOrder == .Oldest {
                bookmarkTable = bookmarkTable.order(Bookmark.Column.id.asc)
            } else {
                bookmarkTable = bookmarkTable.order(Bookmark.Column.id.desc)
            }
            for c in try conn!.prepare(bookmarkTable) {
                let bookmark = Bookmark().buildFromRow(c)
                bookmarks.append(bookmark)
            }
            delegates.forEach({delegate -> () in delegate.1.bookmarksLoaded?() })
        } catch {
            Log.write("Error while loading bookmarks")
        }
    }
    
    func switchSortOrder() {
        if sortOrder == .Latest {
            sortOrder = .Oldest
        } else {
            sortOrder = .Latest
        }
        loadData()
    }
    
    func housekeeping() {
        var collectionIds = [Int]()

        for collection in collectionManager.collections {
            collectionIds.append(collection.id)
        }

        var removeList = [Bookmark]()
        for bookmark in bookmarks {
            var available = false
            for id in collectionIds {
                if bookmark.collectionId == id {
                    available = true
                    break
                }
            }
            if !available {
                removeList.append(bookmark)
            }
        }
        self.remove(removeList)
    }
    
    func remove(hadiths: [Hadith]) {
        var successful = false
        for hadith in hadiths {
            successful = self.remove(hadith.collection!.id, volumeNumber: hadith.volumeNumber, bookNumber: hadith.bookNumber, hadithNumber: hadith.hadithNumber)
        }
        if successful {
            self.loadData()
        }
    }
    
    func remove(bookmarks: [Bookmark]) {
        var successful = false
        for bookmark in bookmarks {
            successful = self.remove(bookmark.collectionId, volumeNumber: bookmark.volumeNumber, bookNumber: bookmark.bookNumber, hadithNumber: bookmark.hadithNumber)
        }
        if successful {
            self.loadData()
        }

    }
    
    private func remove(collectionId : Int,
                        volumeNumber : Int?,
                        bookNumber : Int?,
                        hadithNumber : String) -> Bool {
        do {
            let conn : Connection? = try Connection(databaseManager.userDataDatabaseFile)
            let bookmarkTable = Table(Bookmark.TableName)
            // Delete existing
            var existingBookmark = bookmarkTable.filter(Bookmark.Column.collectionId == collectionId)
            existingBookmark = existingBookmark.filter(Bookmark.Column.volumeNumber == volumeNumber)
            existingBookmark = existingBookmark.filter(Bookmark.Column.bookNumber == bookNumber)
            existingBookmark = existingBookmark.filter(Bookmark.Column.hadithNumber == hadithNumber)
            let deleteExisting = existingBookmark.delete()
            try conn?.run(deleteExisting)
            return true
        } catch {
            Log.write("Failed to remove bookmark")
            Log.write(error)
        }
        return false
    }
    
    func addBookmark(name : String, hadith: Hadith, skipLoadData : Bool = false) -> Bookmark? {
        if (self.bookmarks.count >= maxLimit) {
            delegates.forEach({delegate -> () in delegate.1.bookmarkAddFailed?("You have added maximum allowed bookmarks. Please remove some and try again.") })
            return nil
        }
        do {
            let conn : Connection? = try Connection(databaseManager.userDataDatabaseFile)
            let bookmark = Bookmark()
            bookmark.name = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            bookmark.name = bookmark.name.isEmpty == true ? hadith.availableRef : bookmark.name
            bookmark.volumeNumber = hadith.volumeNumber
            bookmark.bookNumber = hadith.bookNumber
            bookmark.hadithNumber = hadith.hadithNumber
            bookmark.collectionId = hadith.collection!.id
            bookmark.dateAdded = NSDate()
            let bookmarkTable = Table(Bookmark.TableName)
            // Delete existing
            var existingBookmark = bookmarkTable.filter(Bookmark.Column.collectionId == bookmark.collectionId)
            existingBookmark = existingBookmark.filter(Bookmark.Column.volumeNumber == bookmark.volumeNumber)
            existingBookmark = existingBookmark.filter(Bookmark.Column.bookNumber == bookmark.bookNumber)
            existingBookmark = existingBookmark.filter(Bookmark.Column.hadithNumber == bookmark.hadithNumber)
            let deleteExisting = existingBookmark.delete()
            try conn?.run(deleteExisting)
            
            let insert = bookmarkTable.insert(
                Bookmark.Column.name <- bookmark.name,
                Bookmark.Column.volumeNumber <- bookmark.volumeNumber,
                Bookmark.Column.bookNumber <- bookmark.bookNumber,
                Bookmark.Column.hadithNumber <- bookmark.hadithNumber,
                Bookmark.Column.collectionId <- bookmark.collectionId,
                Bookmark.Column.dateAdded <- bookmark.dateAdded
            )
            let rowId : Int64? = try conn?.run(insert)
            if rowId != nil {
                bookmark.id = rowId!
                if !skipLoadData {
                    self.loadData()
                } else {
                    bookmarks.append(bookmark)
                }
                ({
                    if AutoSyncBookmarks.load() == true {
                        self.sync()
                    }
                }) ~> ({})
                return bookmark
            }
        } catch {
            Log.write("Failed to add bookmark")
            Log.write(error)
        }
        delegates.forEach({delegate -> () in delegate.1.bookmarkAddFailed?("Failed to add bookmark. Please try again later.") })
        return nil
    }
    
    func isBookmarked(hadith:Hadith) -> Bool {
        return bookmarks.contains({ bookmark -> Bool in
            return bookmark.matches(hadith)
        })
    }
    
    func sync() {
        if _syncing {
            return
        }
        let accountManager = AccountManager.sharedInstance()
        if accountManager.isLoggedIn {
            self._syncing = true
            var url = "http://muflihun.com/svc/sync-fav-hadith?signintoken=" + accountManager.token!;
            url += "&exportToWeb"
            url += "&importToApp"
            var bookmarkDtoList = [BookmarkDto]()
            for bookmark in self.bookmarks {
                let bookmarkDto = BookmarkDto(collectionNumber: bookmark.collectionId, volumeNumber: bookmark.volumeNumber, bookNumber: bookmark.bookNumber, hadithNumber: bookmark.hadithNumber, name: bookmark.name)
                bookmarkDtoList.append(bookmarkDto)
            }
            let json = bookmarkDtoList.toJSONString()!
            let postString = "data=" + json
            let request = NSMutableURLRequest(URL: NSURL(string: url)!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
            request.HTTPMethod = "POST"
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
            let syncTask = self.syncSession.dataTaskWithRequest(request, completionHandler: { data, response, err -> Void in
                if data == nil {
                    self.delegates.forEach({delegate -> () in delegate.1.syncFailed?("Please check your internet connection") })
                    self._syncing = false
                    return
                }
                if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode == 200 {
                    let json = String(data: data!, encoding:NSUTF8StringEncoding)!
                    let response = BookmarkDto.fromJsonArray(json)
                    let collections = self.collectionManager.getCollectionsMapWithIds();
                    for dto in response {
                        let collection = collections[dto.collectionNumber]
                        if (collection != nil) {
                            let hadith = self.collectionManager.loadHadith(collection!, volumeNumber: dto.volumeNumber, bookNumber: dto.bookNumber, hadithNumber: dto.hadithNumber)
                            if (hadith != nil && !self.isBookmarked(hadith!)) {
                                self.addBookmark(dto.name, hadith: hadith!, skipLoadData: true)
                            }
                        }
                    }
                    self.delegates.forEach({delegate -> () in delegate.1.syncCompleted?() })
                } else {
                    self.delegates.forEach({delegate -> () in delegate.1.syncFailed?("Unexpected error while syncing bookmarks") })
                }
                self._syncing = false
            })
            syncTask.resume()
        } else {
            Log.write("User not logged in")
            delegates.forEach({delegate -> () in delegate.1.syncFailed?("Please sign-in to sync your bookmarks") })
        }
    }

    
    // MARK: Singleton
    struct Static {
        static var instance:BookmarkManager? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> BookmarkManager! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }
    
}