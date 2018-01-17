//
//  NoteManager.swift
//  Hadith
//
//  Created by Majid Khan on 5/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class NoteManager {
    
    let maxLimit = 500
    
    var collectionManager = CollectionManager.sharedInstance()
    var databaseManager = DatabaseManager.sharedInstance()
    var notes = [Note]()
    var sortOrder = SortOrder.Oldest
    var delegates : [String:NoteManagerDelegate] = [:]
    
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
        notes = []
        do {
            let conn : Connection? = try Connection(databaseManager.userDataDatabaseFile)
            var noteTable = Table(Note.TableName)
            
            if sortOrder == .Oldest {
                noteTable = noteTable.order(Note.Column.id.asc)
            } else {
                noteTable = noteTable.order(Note.Column.id.desc)
            }
            let collections = collectionManager.getCollectionsMapWithIds()
            for c in try conn!.prepare(noteTable) {
                let note = Note().buildFromRow(c)
                note.hadith = collectionManager.loadHadith(collections[note.collectionId]!, volumeNumber: note.volumeNumber, bookNumber: note.bookNumber, hadithNumber: note.hadithNumber)
                if note.hadith != nil { // extra check
                    notes.append(note)
                }
            }
            delegates.forEach({delegate -> () in delegate.1.notesLoaded?() })

        } catch {
            Log.write("Error while loading notes")
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
        
        var removeList = [Note]()
        for note in notes {
            var available = false
            for id in collectionIds {
                if note.collectionId == id {
                    available = true
                    break
                }
            }
            if !available {
                removeList.append(note)
            }
        }
        self.remove(removeList)
    }
    
    func update(note : Note, title : String, text: String, lastUpdated: NSDate = NSDate()) {
        do {
            let conn : Connection? = try Connection(databaseManager.userDataDatabaseFile)
            note.title = title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            note.text = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if note.title.isEmpty || note.text.isEmpty {
                Log.write("Failed to add note with empty title/text")
                return
            }
            note.lastUpdated = lastUpdated
            let noteTable = Table(Note.TableName)
            // Check existing
            let existingNote = noteTable.filter(Note.Column.id == note.id)
            let updateStatement = existingNote.update(
                Note.Column.volumeNumber <- note.volumeNumber,
                Note.Column.bookNumber <- note.bookNumber,
                Note.Column.hadithNumber <- note.hadithNumber,
                Note.Column.collectionId <- note.collectionId,
                Note.Column.title <- note.title,
                Note.Column.text <- note.text,
                Note.Column.lastUpdated <- note.lastUpdated
            )
            try conn?.run(updateStatement)
            
            ({
                if AutoSyncNotes.load() == true {
                    self.sync()
                }
            }) ~> ({})
            delegates.forEach({delegate -> () in delegate.1.notesLoaded?() })
        } catch {
            Log.write("Failed to update note")
            Log.write(error)
        }

    }
    
    func buildNoteObj(title : String, text: String, hadith: Hadith) -> Note? {
        let note = Note()
        note.title = title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        note.text = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if note.title.isEmpty || note.text.isEmpty {
            Log.write("Failed to add note with empty title/text")
            delegates.forEach({delegate -> () in delegate.1.notesAddFailed?("Please choose valid title and text") })
            return nil
        }
        note.title = note.title.substringTo(min(note.title.characters.count, 50))
        note.volumeNumber = hadith.volumeNumber
        note.bookNumber = hadith.bookNumber
        note.hadithNumber = hadith.hadithNumber
        note.collectionId = hadith.collection!.id
        note.hadith = hadith
        note.lastUpdated = NSDate()
        return note
    }
    
    func add(title : String, text: String, hadith: Hadith, skipDataLoad : Bool = false) -> Note? {
        let note = buildNoteObj(title, text: text, hadith: hadith)
        if note == nil {
            return nil
        }
        return add(note!, skipDataLoad: skipDataLoad)
    }
    
    func add(note : Note, skipDataLoad : Bool = false) -> Note? {
        if (self.notes.count >= maxLimit) {
            delegates.forEach({delegate -> () in delegate.1.notesAddFailed?("You have added maximum allowed notes. Please remove some and try again.") })
            return nil
        }
        do {
            let conn : Connection? = try Connection(databaseManager.userDataDatabaseFile)
            let noteTable = Table(Note.TableName)
            // Delete existing
            self.remove([note])
            let insert = noteTable.insert(
                Note.Column.volumeNumber <- note.volumeNumber,
                Note.Column.bookNumber <- note.bookNumber,
                Note.Column.hadithNumber <- note.hadithNumber,
                Note.Column.collectionId <- note.collectionId,
                Note.Column.title <- note.title,
                Note.Column.text <- note.text,
                Note.Column.lastUpdated <- note.lastUpdated
            )
            let rowId : Int64? = try conn?.run(insert)
            if rowId != nil {
                note.id = rowId!
                if !skipDataLoad {
                    self.loadData()
                } else {
                    notes.append(note)
                }
                
                ({
                    if AutoSyncNotes.load() == true {
                        self.sync()
                    }
                }) ~> ({})
                return note
            }
        } catch {
            Log.write("Failed to add note")
            Log.write(error)
        }
        delegates.forEach({delegate -> () in delegate.1.notesAddFailed?("Failed to add note. Please try again later.") })
        return nil
    }
    
    func hasNote(hadith:Hadith) -> Bool {
        return notes.contains({ note -> Bool in
            return note.matches(hadith)
        })
    }
    
    func getNote(hadith:Hadith) -> Note? {
        let index = notes.indexOf({ note -> Bool in
            return note.matches(hadith)
        })
        if index != nil {
            return notes[index!]
        }
        return nil
    }
    
    func remove(hadiths: [Hadith]) {
        var successful = false
        for hadith in hadiths {
            successful = successful || self.remove(hadith.collection!.id, volumeNumber: hadith.volumeNumber, bookNumber: hadith.bookNumber, hadithNumber: hadith.hadithNumber)
        }
        if successful {
            self.loadData()
        }
    }
    
    func remove(notes: [Note]) {
        var successful = false
        for note in notes {
            // Even if single note was successful we reload data
            successful = successful || self.remove(note.collectionId, volumeNumber: note.volumeNumber, bookNumber: note.bookNumber, hadithNumber: note.hadithNumber)
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
            var noteTable = Table(Note.TableName)
            noteTable = noteTable.filter(Bookmark.Column.collectionId == collectionId)
            noteTable = noteTable.filter(Bookmark.Column.volumeNumber == volumeNumber)
            noteTable = noteTable.filter(Bookmark.Column.bookNumber == bookNumber)
            noteTable = noteTable.filter(Bookmark.Column.hadithNumber == hadithNumber)
            let deleteExisting = noteTable.delete()
            try conn?.run(deleteExisting)
            return true
        } catch {
            Log.write("Failed to remove note")
            Log.write(error)
        }
        return false
    }
    
    func sync() {
        if _syncing {
            return
        }
        let accountManager = AccountManager.sharedInstance()
        if accountManager.isLoggedIn {
            self._syncing = true
            var url = "http://muflihun.com/svc/sync-hadith-notes?report=hhsc&signintoken=" + accountManager.token!;
            url += "&exportToWeb"
            url += "&importToApp"
            
            var noteDtoList = [NoteDto]()
            for note in self.notes {
                let lastUpdated = note.lastUpdated.formatAsString("yyyy-MM-dd HH:mm:ss")
                let utcLastUpdated = note.lastUpdated.formatAsString("yyyy-MM-dd HH:mm:ss", timezoneAbbrev: "UTC")
                Log.write("LOCAL " + lastUpdated)
                Log.write("UTC " + utcLastUpdated)
                let noteDto = NoteDto(collectionNumber: note.collectionId, volumeNumber: note.volumeNumber, bookNumber: note.bookNumber, hadithNumber: note.hadithNumber, title: note.title, text: note.text, lastUpdated: utcLastUpdated)
                noteDtoList.append(noteDto)
            }
            let json = noteDtoList.toJSONString()!

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
                    let response = NoteDto.fromJsonArray(json)
                    let collections = self.collectionManager.getCollectionsMapWithIds();
                    for dto in response {
                        let collection = collections[dto.collectionNumber]
                        if (collection != nil) {
                            let hadith = self.collectionManager.loadHadith(collection!, volumeNumber: dto.volumeNumber, bookNumber: dto.bookNumber, hadithNumber: dto.hadithNumber)
                            if (hadith != nil) {
                                let receivedLastUpdated = NSDate.fromString(dto.lastUpdated, format: "yyyy-MM-dd HH:mm:ss", timezoneAbbrev: "UTC")!
                                let receivedLastUpdatedLocalStr = receivedLastUpdated.formatAsString("yyyy-MM-dd HH:mm:ss")
                                let receivedLastUpdatedLocal = NSDate.fromString(receivedLastUpdatedLocalStr, format: "yyyy-MM-dd HH:mm:ss")!
                                var note = self.getNote(hadith!)
                                if note == nil {
                                    note = self.buildNoteObj(dto.title, text: dto.text, hadith: hadith!)
                                    if note == nil {
                                        continue;
                                    }
                                    note!.lastUpdated = receivedLastUpdatedLocal
                                    self.add(note!, skipDataLoad : true)
                                } else {
                                    Log.write("Updating note " + note!.title + " - to - " + dto.title)

                                    note!.title = dto.title
                                    note!.text = dto.text
                                    self.update(note!, title: dto.title, text: dto.text, lastUpdated: receivedLastUpdatedLocal)
                                    
                                }
                            }
                        }
                    }
                    self.delegates.forEach({delegate -> () in delegate.1.syncCompleted?() })
                } else {
                    self.delegates.forEach({delegate -> () in delegate.1.syncFailed?("Unexpected error while syncing notes") })
                }
                self._syncing = false
            })
            syncTask.resume()
            
        } else {
            Log.write("User not logged in")
            delegates.forEach({delegate -> () in delegate.1.syncFailed?("Please sign-in to sync your notes") })
        }
    }
    
    
    // MARK: Singleton
    struct Static {
        static var instance:NoteManager? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> NoteManager! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }

}