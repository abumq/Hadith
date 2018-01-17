//
//  CrossReference.swift
//  Hadith
//
//  Created by Majid Khan on 3/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

import ObjectMapper

class CrossReference : NSObject, Mappable  {
    var text : String!
    var link : String!
    
    override init() {
    }
    
    init(text:String, link:String) {
        self.text = text
        self.link = link
    }
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        self.text <- map["t"]
        self.link <- map["l"]
    }
    
    class func fromJson(json:String) -> CrossReference? {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "{"
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "}" {
            return nil
        }
        return Mapper<CrossReference>().map(json)!
    }
    
    class func fromJsonArray(json:String) -> [CrossReference] {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "["
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "]"{
            return []
        }
        return Mapper<CrossReference>().mapArray(json)!
    }
}