//
//  DatabaseManager.swift
//  Hadith
//
//  Created by Majid Khan on 3/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class DatabaseManager {
    
    private static let databaseMetaInfoFilename = "meta.json"
    private static let updateDatabaseMetaInfoInterval = 30.0
    private static let defaultVersionInfo : [String:DatabaseMetaInfo] = [
        "master" : DatabaseMetaInfo(id: "master", name: "Master Database", version: 1, details: "Master database contains meta information of data structure and some other basic information.", url: "AppStore", size: 0, requiredAppVersion: 1.0),
        "search" : DatabaseMetaInfo(id: "search", name: "Search", version: 1, details: "Provides searchable keywords for fast searching", url: "AppStore", size: 0, requiredAppVersion: 1.0)
    ]
    static let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
    private var _databaseMetaInfo : [String:DatabaseMetaInfo] = [:]
    private var _databaseMetaInfoLastUpdated : UpdateLastCheckedSetting
    private var localCheckTimer : NSTimer?
    
    var databaseMetaInfoFile : String {
        get { return (DatabaseManager.documentsDirectory! as NSString).stringByAppendingPathComponent(DatabaseManager.databaseMetaInfoFilename) }

    }
    var databaseMetaInfo : [String:DatabaseMetaInfo] {
        get {
            return self._databaseMetaInfo
        }
    }
    
    var masterDatabase : DatabaseMetaInfo? = nil
    var masterDatabaseFile : String? {
        get {
            return masterDatabase?.databaseFile
        }
    }
    
    var searchDatabase : DatabaseMetaInfo? = nil
    var searchDatabaseFile : String? {
        get {
            return searchDatabase?.databaseFile
        }
    }
    
    private var _userDataDatabaseFile : String = ""
    
    var userDataDatabaseFile : String {
        get {
            return self._userDataDatabaseFile
        }
    }
    
    // MARK: Singleton
    struct Static {
        static var instance:DatabaseManager? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> DatabaseManager! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }
    
    required init() {
        _databaseMetaInfoLastUpdated = UpdateLastCheckedSetting()
        // Ensure we have database files in-place
        for key in DatabaseManager.defaultVersionInfo.keys {
            let databaseMetaInfo = DatabaseManager.defaultVersionInfo[key]!
            let path = databaseMetaInfo.databaseFile
            Utils.moveFromBundleToDocument(path, destName: databaseMetaInfo.filename)
        }
        
        // User's data database is not part of version.json so we manually update it
        // as user shouldn't be allowed to "update" this database
        let userDataDatabaseFileName = "db-userdata.db"
        let path = (DatabaseManager.documentsDirectory! as NSString).stringByAppendingPathComponent(userDataDatabaseFileName)
        self._userDataDatabaseFile = path        
        
        self.setupUserData()
        self.localCheckTimer = NSTimer.scheduledTimerWithTimeInterval(DatabaseManager.updateDatabaseMetaInfoInterval, target: self, selector: #selector(DatabaseManager.updateDatabaseMetaInfo), userInfo: nil, repeats: true)
        self.localCheckTimer?.fire()
        if (self.masterDatabaseFile == nil || !NSFileManager.defaultManager().fileExistsAtPath(self.masterDatabaseFile!)) {
            Log.write("Failed to initialize DatabaseManager. Master database does not exist")
        }
    }
    
    private func setupUserData() {
        do {
            let conn = try Connection(userDataDatabaseFile)
            // Bookmark
            let bookmarkTableExists = Utils.databaseTableExists(Bookmark.TableName, connection: conn)
            if (bookmarkTableExists == false) {
                Log.write("Setting up [\(Bookmark.TableName)]")
                let bookmarkTable = Table(Bookmark.TableName)
                try conn.run(bookmarkTable.create { t in
                    t.column(Bookmark.Column.id, primaryKey: true)
                    t.column(Bookmark.Column.name)
                    t.column(Bookmark.Column.collectionId)
                    t.column(Bookmark.Column.volumeNumber)
                    t.column(Bookmark.Column.hadithNumber)
                    t.column(Bookmark.Column.bookNumber)
                    t.column(Bookmark.Column.dateAdded)
                    })
                try conn.run(bookmarkTable.createIndex(
                    [Bookmark.Column.collectionId,
                        Bookmark.Column.volumeNumber,
                        Bookmark.Column.bookNumber,
                        Bookmark.Column.hadithNumber], unique: true))
            }
            // Note
            let noteTableExists = Utils.databaseTableExists(Note.TableName, connection: conn)
            if (noteTableExists == false) {
                Log.write("Setting up [\(Note.TableName)]")
                let noteTable = Table(Note.TableName)
                try conn.run(noteTable.create { t in
                    t.column(Note.Column.id, primaryKey: true)
                    t.column(Note.Column.collectionId)
                    t.column(Note.Column.volumeNumber)
                    t.column(Note.Column.hadithNumber)
                    t.column(Note.Column.bookNumber)
                    t.column(Note.Column.title)
                    t.column(Note.Column.text)
                    t.column(Note.Column.lastUpdated)
                    })
                try conn.run(noteTable.createIndex(
                    [Note.Column.collectionId,
                        Note.Column.volumeNumber,
                        Note.Column.bookNumber,
                        Note.Column.hadithNumber], unique: true))
                try conn.run(noteTable.createIndex(Note.Column.title))
            }
        } catch {
            Log.write(error)
        }
    }
    
    func database(id: String) -> DatabaseMetaInfo? {
        return self.databaseMetaInfo[id]
    }
    
    func databaseFile(id: String) -> String? {
        if let database = self.databaseMetaInfo[id] {
            return database.databaseFile
        }
        return nil
    }
    
    func removeDatabaseMetaInfo(id:String) {
        self._databaseMetaInfo.removeValueForKey(id)
    }
    
    func addOrUpdateDatabaseMetaInfo(databaseMetaInfo:DatabaseMetaInfo) {
        self._databaseMetaInfo[databaseMetaInfo.id] = databaseMetaInfo
    }
    
    func rewriteDatabaseMetaInfo() {
        do {
            let json : String? = Array(self._databaseMetaInfo.values).toJSONString()
            let finalJson = json == nil ? "" : json! // to cast String? to String to prevent Optional()
            try finalJson.writeToFile(self.databaseMetaInfoFile, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            Log.write(error)
        }
    }
    
    @objc private func updateDatabaseMetaInfo() {
        let fm = NSFileManager.defaultManager()
        do {
            if (!fm.fileExistsAtPath(self.databaseMetaInfoFile)) {
                Log.write("Database version file not found! Creating...")
                self._databaseMetaInfo = DatabaseManager.defaultVersionInfo
                self.rewriteDatabaseMetaInfo()
            }
            self._databaseMetaInfo = [:]
            let json = try String(contentsOfFile: self.databaseMetaInfoFile, encoding: NSUTF8StringEncoding)
            for info in DatabaseMetaInfo.fromJsonArray(json) {
                self._databaseMetaInfo[info.id] = info
            }
            self.masterDatabase = self._databaseMetaInfo["master"]
            self.searchDatabase = self._databaseMetaInfo["search"]
            self._databaseMetaInfoLastUpdated.value = NSDate()
        } catch {
            Log.write(error)
        }
    }
}