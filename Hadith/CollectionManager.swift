//
//  CollectionManager.swift
//  Hadith
//
//  Created by Majid Khan on 17/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite

typealias HadithByLanguage = [String:(language:Language, hadith:Hadith)]

class CollectionManager {
    static let defaultThumbAssetName = "default-thumb"
    var databaseManager = DatabaseManager.sharedInstance()
    private var _collections = [Collection]()
    private var _languages = [Int: [Language]]()
    var delegates : [String:CollectionManagerDelegate] = [:]
    
    required init() {
        self.loadData()
    }
    
    var collections : [Collection] {
        get {
            return _collections
        }
    }
    var languages : [Int: [Language]] {
        get {
            return _languages
        }
    }
    
    func loadData() {
        var emptyDataTitle = ""
        var emptyDataDescription = ""
        _collections.removeAll()
        _languages.removeAll()
        if (databaseManager.masterDatabaseFile == nil) {
            emptyDataTitle = "No Data Found"
            emptyDataDescription = "Please download to continue."
        }
        if (Double(Utils.appVersion) < databaseManager.masterDatabase?.requiredAppVersion) {
            emptyDataTitle = "Update Your App"
            emptyDataDescription = "Please update your app from AppStore.\nMinimum app version required: v\(databaseManager.masterDatabase?.requiredAppVersion)"
        }
        do {
            let conn : Connection? = try Connection(databaseManager.masterDatabaseFile!)
            let collectionTable = Table(Collection.TableName).order(Collection.Column.id)
            for c in try conn!.prepare(collectionTable) {
                let collection = Collection().buildFromRow(c)
                guard let _ = databaseManager.database(collection.identifier) else {
                    Log.write("Could not find database for \(collection.identifier)")
                    continue
                }
                _collections.append(collection)
            }
            
            let languageTable = Table(Language.TableName)
            for lang in try conn!.prepare(languageTable) {
                let language = Language().buildFromRow(lang)
                guard let _ = databaseManager.database(language.identifier) else {
                    continue
                }
                if _languages[language.collectionNumber] == nil {
                    _languages[language.collectionNumber] = []
                }
                _languages[language.collectionNumber]!.append(language)
            }

            if _collections.isEmpty {
                emptyDataTitle = "Setup"
                emptyDataDescription = "Please download to continue."
            }
        } catch {
            emptyDataTitle = "Setup"
            emptyDataDescription = "Master database not found.\n\nPlease download to continue."
            Log.write(error)
        }
        delegates.forEach({delegate -> () in delegate.1.dataLoaded?(emptyDataTitle, emptyDataDescription: emptyDataDescription) })
    }
    
    func getCollectionsMapWithIdentifiers() -> [String:Collection] {
        var map : [String:Collection] = [:]
        for collection in self.collections {
            map[collection.identifier] = collection
        }
        return map
    }
    
    func getCollectionsMapWithIds() -> [Int:Collection] {
        var map : [Int:Collection] = [:]
        for collection in self.collections {
            map[collection.id] = collection
        }
        return map
    }
    
    func thumbnailUpdated(collection: Collection) {
        delegates.forEach({delegate -> () in delegate.1.thumbnailUpdated?(collection.identifier) })
    }
    
    func loadHadithListForBooks(collection : Collection, books : [Book], inout emptyDataInfo : EmptyDataInfo) -> [Hadith] {
        
        guard let db = self.databaseManager.database(collection.identifier) else {
            emptyDataInfo = ("No Data Found", "Please download to continue.", .Data, true)
            return []
        }
        if (Double(Utils.appVersion) < db.requiredAppVersion) {
            emptyDataInfo = ("Update Your App", "Please update your app from AppStore.\nMinimum app version required: v\(db.requiredAppVersion)", .Data, false)
            return []
        }
        var hadithResultList = [Hadith]()
        do {
            let dbFile = self.databaseManager.databaseFile(db.id)
            let conn : Connection? = try Connection(dbFile!)
            for book in books {
                var hadithTable = Table(Hadith.TableName)
                hadithTable = hadithTable.filter(Hadith.Column.collectionNumber == collection.id)
                hadithTable = hadithTable.filter(Hadith.Column.bookNumber == book.bookNumber)
                hadithTable = hadithTable.order(Hadith.Column.Cast.hadithNumberInt)
                for h in try conn!.prepare(hadithTable) {
                    let hadith = Hadith().buildFromRow(h)
                    hadith.collection = collection
                    hadith.book = book
                    hadithResultList.append(hadith)
                }
            }
        } catch {
            emptyDataInfo = ("Data Corrupted", "Please check updates to continue.", .Data, true)
            Log.write(error)
        }
        return hadithResultList
    }
    
    func loadHadithListForCollection(collection : Collection, inout emptyDataInfo : EmptyDataInfo) -> [Hadith] {
        if collection.hasBooks {
            // early return hadith with "book" field
            return self.loadHadithListForBooks(collection, books: self.loadBookList(collection, emptyDataInfo: &emptyDataInfo), emptyDataInfo: &emptyDataInfo)
        }
        guard let db = self.databaseManager.database(collection.identifier) else {
            emptyDataInfo = ("No Data Found", "Please download to continue.", .Data, true)
            return []
        }
        
        if (Double(Utils.appVersion) < db.requiredAppVersion) {
            emptyDataInfo = ("Update Your App", "Please update your app from AppStore.\nMinimum app version required: v\(db.requiredAppVersion)", .Data, false)
            return []
        }
        var resultList = [Hadith]()
        do {
            let dbFile = self.databaseManager.databaseFile(db.id)
            let conn : Connection? = try Connection(dbFile!)
            var hadithTable = Table(Hadith.TableName)
            hadithTable = hadithTable.filter(Hadith.Column.collectionNumber == collection.id)
            hadithTable = hadithTable.order(Hadith.Column.Cast.hadithNumberInt)
            for h in try conn!.prepare(hadithTable) {
                let hadith = Hadith().buildFromRow(h)
                hadith.collection = collection
                resultList.append(hadith)
            }
        } catch {
            emptyDataInfo = ("Data Corrupted", "Please check updates to continue.", .Data, true)
            Log.write(error)
        }
        return resultList
    }
    
    
    func loadBookList(collection:Collection, inout emptyDataInfo : EmptyDataInfo) -> [Book] {
        
        guard let db = self.databaseManager.database(collection.identifier) else {
            emptyDataInfo = ("No Data Found", "Please download to continue.", .Data, true)
            return []
        }
        if (Double(Utils.appVersion) < db.requiredAppVersion) {
            emptyDataInfo = ("Update Your App", "Please update your app from AppStore.\nMinimum app version required: v\(db.requiredAppVersion)", .Data, false)
            return []
        }
        var bookResultList = [Book]()
        do {
            let dbFile = self.databaseManager.databaseFile(db.id)
            let conn : Connection? = try Connection(dbFile!)
            var bookTable = Table(Book.TableName)
            bookTable = bookTable.filter(Book.Column.collectionNumber == collection.id)
            bookTable = bookTable.order(Book.Column.bookNumber)
            for b in try conn!.prepare(bookTable) {
                let book = Book().buildFromRow(b)
                book.collection = collection
                if collection.hasBooks {
                    var hadithTable = Table(Hadith.TableName)
                    hadithTable = hadithTable.filter(Hadith.Column.collectionNumber == book.collectionNumber)
                    hadithTable = hadithTable.filter(Hadith.Column.bookNumber == book.bookNumber)
                    if collection.hasVolumes {
                        hadithTable = hadithTable.filter(Hadith.Column.volumeNumber == book.volumeNumber)
                    }
                    hadithTable = hadithTable.order(Hadith.Column.Cast.hadithNumberInt.asc)
                    hadithTable = hadithTable.limit(1)
                    for h in try conn!.prepare(hadithTable) {
                        let hadith = Hadith().buildFromRow(h)
                        book.lowerLimit = hadith.hadithNumber
                    }
                    hadithTable = hadithTable.order(Hadith.Column.Cast.hadithNumberInt.desc)
                    hadithTable = hadithTable.limit(1)
                    for h in try conn!.prepare(hadithTable) {
                        let hadith = Hadith().buildFromRow(h)
                        book.upperLimit = hadith.hadithNumber
                    }
                }
                bookResultList.append(book)
            }
        } catch {
            emptyDataInfo = ("Data Corrupted", "Please check updates to continue.", .Data, true)
            Log.write(error)
        }
        return bookResultList
    }
    
    func loadBook(collection : Collection, bookNumber : Int) -> Book? {
        guard let db = databaseManager.database(collection.identifier) else {
            return nil
        }
        if (Double(Utils.appVersion) < db.requiredAppVersion) {
            return nil
        }
        if (!collection.hasBooks) {
            return nil
        }
        do {
            let dbFile = databaseManager.databaseFile(db.id)
            let conn : Connection? = try Connection(dbFile!)
            var book : Book?
            var bookTable = Table(Book.TableName)
            bookTable = bookTable.filter(Book.Column.collectionNumber == collection.id)
            bookTable = bookTable.filter(Book.Column.bookNumber == bookNumber)
            for b in try conn!.prepare(bookTable) {
                book = Book().buildFromRow(b)
                book!.collection = collection
                // We expect one book only

                return book
            }
            return nil
        } catch {
            Log.write(error)
        }
        return nil
    }
    
    func loadHadith(collection : Collection, volumeNumber : Int?, bookNumber : Int?, hadithNumber : String) -> Hadith? {
        guard let db = databaseManager.database(collection.identifier) else {
            return nil
        }
        if (Double(Utils.appVersion) < db.requiredAppVersion) {
            return nil
        }
        do {
            let dbFile = databaseManager.databaseFile(db.id)
            let conn : Connection? = try Connection(dbFile!)
            var hadithTable = Table(Hadith.TableName)
            if collection.hasBooks {
                hadithTable = hadithTable.filter(Hadith.Column.bookNumber == bookNumber)
            }
            if volumeNumber != nil {
                hadithTable = hadithTable.filter(Hadith.Column.volumeNumber == volumeNumber)
            }
            hadithTable = hadithTable.filter(Hadith.Column.hadithNumber == hadithNumber)
            for h in try conn!.prepare(hadithTable) {
                let hadith = Hadith().buildFromRow(h)
                hadith.collection = collection
                if bookNumber != nil && collection.hasBooks {
                    hadith.book = loadBook(collection, bookNumber: bookNumber!)
                }
                // We expect one hadith only
                return hadith
            }
            return nil
        } catch {
            Log.write(error)
        }
        return nil
    }
    
    func loadHadithAndLanguages(hadith: Hadith) -> HadithByLanguage? {
        var hadithByLanguages : HadithByLanguage = [:]
        if (databaseManager.masterDatabaseFile == nil) {
             Log.write("Unable to find master database")
            return nil
        }
        if (Double(Utils.appVersion) < databaseManager.masterDatabase?.requiredAppVersion) {
             Log.write("Must update app. Master database cannot be loaded")
            return nil
        }
        do {
            if self.languages[hadith.collectionNumber] == nil {
                 Log.write("Unexpected problem: self.languages[hadith.collectionNumber] == nil")
                return nil
            }
            let languagesForCollection = self.languages[hadith.collectionNumber]!
            for language in languagesForCollection {
                let conn : Connection? = try Connection(databaseManager.databaseFile(language.identifier)!)
                var hadithTable = Table(Hadith.TableName)
                hadithTable = hadithTable.filter(Hadith.Column.collectionNumber == hadith.collectionNumber)
                if (hadith.book != nil) {
                    hadithTable = hadithTable.filter(Hadith.Column.bookNumber == hadith.bookNumber)
                }
                hadithTable = hadithTable.filter(Hadith.Column.hadithNumber == hadith.hadithNumber)
                // Only one record is expected
                for row in try conn!.prepare(hadithTable) {
                    let h = Hadith().buildFromRow(row)
                    // Use collection and book from original hadith
                    h.collection = hadith.collection
                    h.book = hadith.book
                    // Use some values from original hadith
                    h.grade = hadith.grade
                    h.hadithGrades = hadith.hadithGrades
                    h.refTags = hadith.refTags
                    h.references = hadith.references
                    h.links = hadith.links
                    h.fontFamily = language.fontFamily
                    h.fontSize = language.fontSize
                    h.direction = language.direction
                    hadithByLanguages[language.name] = (language, h)
                }
            }
            
            // Default values to cover the nils
            for language in languagesForCollection {
                if hadithByLanguages[language.name] == nil {
                    let newHadithNoText = Hadith()
                    newHadithNoText.book = hadith.book
                    newHadithNoText.bookNumber = hadith.bookNumber
                    newHadithNoText.collection = hadith.collection
                    newHadithNoText.collectionNumber = hadith.collectionNumber
                    newHadithNoText.hadithNumber = hadith.hadithNumber
                    newHadithNoText.grade = hadith.grade
                    newHadithNoText.hadithGrades = hadith.hadithGrades
                    newHadithNoText.languageId = language.id
                    newHadithNoText.refTags = hadith.refTags
                    newHadithNoText.references = hadith.references
                    newHadithNoText.links = hadith.links
                    newHadithNoText.volumeNumber = hadith.volumeNumber
                    newHadithNoText.text = "[Hadith not available in this language]"
                    newHadithNoText.fontSize = Language.defaultFontSize
                    newHadithNoText.direction = Language.Direction(rawValue: Language.defaultTextDirectionID)
                    hadithByLanguages[language.name] = (language, newHadithNoText)
                }
            }
            
        } catch {
            Log.write(error)
        }
        return hadithByLanguages
    }
    
    func loadSiblings(hadith:Hadith) -> (index:Int, hadithList:[Hadith])? {
        var result : (index:Int, hadithList:[Hadith]) = (0, [])
        
        let collection = hadith.collection!
        do {
            let dbFile = databaseManager.databaseFile(collection.identifier)
            let conn : Connection? = try Connection(dbFile!)
            var hadithTable = Table(Hadith.TableName)
            hadithTable = hadithTable.filter(Hadith.Column.collectionNumber == collection.id)
            var book : Book?
            var bookTable = Table(Book.TableName)
            bookTable = bookTable.filter(Book.Column.collectionNumber == collection.id)
            
            if (hadith.bookNumber != nil) {
                bookTable = bookTable.filter(Book.Column.bookNumber == hadith.bookNumber!)
                hadithTable = hadithTable.filter(Hadith.Column.bookNumber == hadith.bookNumber)
            }
            for b in try conn!.prepare(bookTable) {
                // We expect single result
                book = Book().buildFromRow(b)
                book!.collection = collection
            }
            
            hadithTable = hadithTable.order(Hadith.Column.Cast.hadithNumberInt)
            hadith.book = book
            var hadiths = [Hadith]()
            for h in try conn!.prepare(hadithTable) {
                let newHadith = Hadith().buildFromRow(h)
                newHadith.collection = collection
                newHadith.book = book
                hadiths.append(newHadith)
                if collection.id == newHadith.collectionNumber && newHadith.id == hadith.id {
                    result.index = hadiths.count - 1
                }
            }
            result.hadithList = hadiths
            return result
        } catch {
            Log.write("Error while making list")
        }
        return nil
    }
    
    // MARK: Singleton
    struct Static {
        static var instance:CollectionManager? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> CollectionManager! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }
}