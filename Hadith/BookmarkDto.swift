//
//  BookmarkDto.swift
//  Hadith
//
//  Created by Majid Khan on 13/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import ObjectMapper

class BookmarkDto : NSObject, Mappable  {
    var collectionNumber : Int = 0
    var volumeNumber : Int? = nil
    var bookNumber : Int? = nil
    var hadithNumber : String = "0"
    var name : String = ""
    
    override init() {
    }
    
    convenience init(collectionNumber: Int, volumeNumber: Int?, bookNumber: Int?, hadithNumber: String, name: String) {
        self.init()
        self.collectionNumber = collectionNumber
        self.volumeNumber = volumeNumber
        self.bookNumber = bookNumber
        self.hadithNumber = hadithNumber
        self.name = name
    }
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        self.collectionNumber <- map["c"]
        self.volumeNumber <- map["v"]
        self.bookNumber <- map["b"]
        self.hadithNumber <- map["h"]
        self.name <- map["n"]
    }
    
    class func fromJson(json:String) -> BookmarkDto? {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "{"
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "}" {
            return nil
        }
        return Mapper<BookmarkDto>().map(json)!
    }
    
    class func fromJsonArray(json:String) -> [BookmarkDto] {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "["
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "]"{
            return []
        }
        return Mapper<BookmarkDto>().mapArray(json)!
    }
}