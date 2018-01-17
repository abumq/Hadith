//
//  HadithToday.swift
//  Hadith
//
//  Created by Majid Khan on 20/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import ObjectMapper

class HadithToday : NSObject, Mappable  {
    var link : String = ""
    var text : String = ""
    var ref : String = ""
    
    override init() {
    }
    
    convenience init(link: String, text: String, ref: String) {
        self.init()
        self.link = link
        self.text = text
        self.ref = ref
    }
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        self.link <- map["link"]
        self.text <- map["text"]
        self.ref <- map["ref"]
    }
    
    class func fromJson(json:String) -> HadithToday? {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "{"
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "}" {
            return nil
        }
        return Mapper<HadithToday>().map(json)!
    }
}