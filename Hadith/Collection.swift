//
//  Collection.swift
//  Hadith
//
//  Created by Majid Khan on 29/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class Collection : BaseModel {
    static let TableName = "Collection"
    struct Column {
        static let id = Expression<Int>("id")
        static let identifier = Expression<String>("identifier")
        static let name = Expression<String>("name")
        static let arabicName = Expression<String?>("arabic_name")
        static let shortName = Expression<String>("short_name")
        static let mediumName = Expression<String>("medium_name")
        static let hasBooks = Expression<Int>("has_books")
        static let hasVolumes = Expression<Int>("has_volumes")
        static let totalHadiths = Expression<Int>("total_hadiths")
    }
    
    var id : Int = 0
    var identifier : String = ""
    var name : String = ""
    var arabicName : String? = ""
    var shortName : String = ""
    var mediumName : String = ""
    var hasBooks : Bool = false
    var hasVolumes : Bool = false
    var totalHadiths : Int = 0
    
    override func buildFromRow(row: Row) -> Collection {
        self.id = row[Column.id]
        self.identifier = row[Column.identifier]
        self.name = row[Column.name]
        self.arabicName = row[Column.arabicName]
        self.shortName = row[Column.shortName]
        self.mediumName = row[Column.mediumName]
        let hasBooksInt = row[Column.hasBooks]
        let hasVolumesInt = row[Column.hasVolumes]
        self.hasBooks = hasBooksInt != 0
        self.hasVolumes = hasVolumesInt != 0
        self.totalHadiths = row[Column.totalHadiths]
        return self
    }
    
}