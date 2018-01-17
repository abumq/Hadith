//
//  Note.swift
//  Hadith
//
//  Created by Majid Khan on 5/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class Note : BaseModel {
    static let TableName = "Note"
    
    struct Column {
        static let id = Expression<Int64>("id")
        static let collectionId = Expression<Int>("collection_id")
        static let volumeNumber = Expression<Int?>("volume_number")
        static let bookNumber = Expression<Int?>("book_number")
        static let hadithNumber = Expression<String>("hadith_number")
        static let title = Expression<String>("title")
        static let text = Expression<String>("text")
        static let lastUpdated = Expression<NSDate>("last_updated")
    }
    
    var id : Int64 = 0
    var collectionId : Int = 0
    var volumeNumber : Int?
    var bookNumber : Int?
    var hadithNumber : String = ""
    var title : String = ""
    var text : String = ""
    var lastUpdated : NSDate = NSDate()
    
    var hadith : Hadith?
    
    
    var excerptText : String {
        var excerptText = self.text;
        excerptText = excerptText.stringByReplacingOccurrencesOfString("\n", withString: " ")
        return excerptText.characters.count > 150 ? excerptText.substringTo(150) + " ..." : excerptText
    }
    
    override func buildFromRow(row: Row) -> Note {
        self.id = row[Column.id]
        self.collectionId = row[Column.collectionId]
        self.volumeNumber = row[Column.volumeNumber]
        self.bookNumber = row[Column.bookNumber]
        self.hadithNumber = row[Column.hadithNumber]
        self.title = row[Column.title]
        self.text = row[Column.text]
        self.lastUpdated = row[Column.lastUpdated]
        return self
    }
    
    func matches(hadith : Hadith) -> Bool {
        return hadith.collectionNumber == collectionId
            && hadith.volumeNumber == volumeNumber
            && hadith.bookNumber == bookNumber
            && hadith.hadithNumber == hadithNumber
    }
    
}