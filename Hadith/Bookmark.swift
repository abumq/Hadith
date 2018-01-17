//
//  Bookmark.swift
//  Hadith
//
//  Created by Majid Khan on 14/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class Bookmark : BaseModel {
    static let TableName = "Bookmark"
    
    struct Column {
        static let id = Expression<Int64>("id")
        static let name = Expression<String>("name")
        static let collectionId = Expression<Int>("collection_id")
        static let volumeNumber = Expression<Int?>("volume_number")
        static let bookNumber = Expression<Int?>("book_number")
        static let hadithNumber = Expression<String>("hadith_number")
        static let dateAdded = Expression<NSDate>("date_added")
    }
    
    var id : Int64 = 0
    var name : String = ""
    var collectionId : Int = 0
    var volumeNumber : Int?
    var bookNumber : Int?
    var hadithNumber : String = ""
    var dateAdded : NSDate = NSDate()
    
    override func buildFromRow(row: Row) -> Bookmark {
        self.id = row[Column.id]
        self.name = row[Column.name]
        self.collectionId = row[Column.collectionId]
        self.volumeNumber = row[Column.volumeNumber]
        self.bookNumber = row[Column.bookNumber]
        self.hadithNumber = row[Column.hadithNumber]
        self.dateAdded = row[Column.dateAdded]
        return self
    }
    
    func matches(hadith : Hadith) -> Bool {
        return hadith.collectionNumber == collectionId
            && hadith.volumeNumber == volumeNumber
            && hadith.bookNumber == bookNumber
            && hadith.hadithNumber == hadithNumber
    }

}