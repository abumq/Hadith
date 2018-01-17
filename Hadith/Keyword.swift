//
//  Keyword.swift
//  Hadith
//
//  Created by Majid Khan on 8/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class Keyword : BaseModel {
    static let TableName = "Keyword"

    struct Column {
        static let id = Expression<Int>("id")
        static let text = Expression<String>("text")
    }
    
    var id : Int = 0
    var text : String = ""
    
    override func buildFromRow(row: Row) -> Keyword {
        self.id = row[Column.id]
        self.text = row[Column.text]
        return self
    }
}