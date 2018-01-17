//
//  NoteDto.swift
//  Hadith
//
//  Created by Majid Khan on 14/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import ObjectMapper

class NoteDto : NSObject, Mappable  {
    var collectionNumber : Int = 0
    var volumeNumber : Int? = nil
    var bookNumber : Int? = nil
    var hadithNumber : String = "0"
    var title : String = ""
    var text : String = ""
    var lastUpdated : String = ""
    
    override init() {
    }
    
    convenience init(collectionNumber: Int, volumeNumber: Int?, bookNumber: Int?, hadithNumber: String, title: String, text: String, lastUpdated: String) {
        self.init()
        self.collectionNumber = collectionNumber
        self.volumeNumber = volumeNumber
        self.bookNumber = bookNumber
        self.hadithNumber = hadithNumber
        self.title = title
        self.text = text
        self.lastUpdated = lastUpdated
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
        self.title <- map["title"]
        self.text <- map["text"]
        self.lastUpdated <- map["lastUpdated"]
    }
    
    class func fromJson(json:String) -> NoteDto? {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "{"
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "}" {
            return nil
        }
        return Mapper<NoteDto>().map(json)!
    }
    
    class func fromJsonArray(json:String) -> [NoteDto] {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "["
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "]"{
            return []
        }
        return Mapper<NoteDto>().mapArray(json)!
    }
}