//
//  Language.swift
//  Hadith
//
//  Created by Majid Khan on 10/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite
import UIKit

class Language : BaseModel {
    enum Direction : Int {
        case LeftToRight = 1
        case RightToLeft = 2
    }
    static let defaultFontSize = 16
    static let defaultTextDirectionID = Direction.LeftToRight.rawValue
    
    static let TableName = "Language"

    struct Column {
        static let id = Expression<Int>("id")
        static let identifier = Expression<String>("identifier")
        static let name = Expression<String>("name")
        static let collectionNumber = Expression<Int>("collection_id")
        static let directionId = Expression<Int>("direction")
        static let fontFamily = Expression<String?>("font_family")
        static let fontSize = Expression<Int?>("font_size")
    }
    
    var id : Int = 0
    var identifier : String = ""
    var name : String = ""
    var collectionNumber : Int = 0
    var directionId : Int = Language.defaultTextDirectionID
    var fontSize : Int? = 0
    var fontFamily : String?
    
    var direction : Direction {
        get {
            if directionId == 1 || directionId == 2 {
                return Direction(rawValue: directionId)!
            }
            return Direction.LeftToRight
        }
    }
    
    override func buildFromRow(row: Row) -> Language {
        self.id = row[Column.id]
        self.identifier = row[Column.identifier]
        self.name = row[Column.name]
        self.collectionNumber = row[Column.collectionNumber]
        self.directionId = row[Column.directionId]
        self.fontFamily = row[Column.fontFamily]
        self.fontSize = row[Column.fontSize]
        return self
    }
}