//
//  Book.swift
//  Hadith
//
//  Created by Majid Khan on 29/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class Book : BaseModel {
    static let TableName = "Book"
    struct Column {
        static let id = Expression<Int>("id")
        static let collectionNumber = Expression<Int>("collection_id")
        static let volumeNumber = Expression<Int?>("volume")
        static let bookNumber = Expression<Int>("number")
        static let name = Expression<String>("name")
        static let arabicName = Expression<String?>("arabic_name")
        static let totalHadiths = Expression<Int>("total_hadiths")
    }
    
    var id : Int = 0
    var collectionNumber : Int = 0
    var volumeNumber : Int? = nil
    var bookNumber : Int = 0
    var name : String = ""
    var arabicName : String? = ""
    var totalHadiths : Int = 0
    
    // Non-fields
    var collection : Collection?
    var lowerLimit : String?
    var upperLimit : String?
    
    override func buildFromRow(row: Row) -> Book {
        self.id = row[Column.id]
        self.collectionNumber = row[Column.collectionNumber]
        self.volumeNumber = row[Column.volumeNumber]
        self.bookNumber = row[Column.bookNumber]
        self.name = row[Column.name]
        self.arabicName = row[Column.arabicName]
        self.totalHadiths = row[Column.totalHadiths]
        return self
    }
}