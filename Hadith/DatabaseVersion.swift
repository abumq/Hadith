//
//  DatabaseMetaInfo.swift
//  Hadith
//
//  Created by Majid Khan on 3/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import ObjectMapper

class DatabaseMetaInfo : NSObject, Mappable {
    enum UpdateType {
        case NoUpdate
        case Pending
        case Available
        case Retired
        case Remove
        case Failed
    }
    let databaseFileFormat = "db-%@.db"
    var id : String = String()
    var name : String = String()
    var version : Int = -1
    var details : String = String()
    var url : String = String()
    var size : Double = -1
    var requiredAppVersion : Double = 1
    var updateType : UpdateType = .NoUpdate
    var thumbUrl: String = ""
    
    var filename : String {
        get { return String(format:self.databaseFileFormat, self.id) }
    }
    
    override init() {
    }
    
    init(id:String, name:String, version:Int, details:String, url:String, size:Double, requiredAppVersion: Double) {
        self.id = id
        self.name = name
        self.version = version
        self.details = details
        self.url = url
        self.size = size
        self.requiredAppVersion = requiredAppVersion
    }
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    var databaseFile : String {
        return (DatabaseManager.documentsDirectory! as NSString).stringByAppendingPathComponent(String(format:self.databaseFileFormat, self.id))

    }
    
    var thumbnailFile : String? {
        get {
            if self.thumbUrl == "" {
                return nil
            }
            return (DatabaseManager.documentsDirectory! as NSString).stringByAppendingPathComponent(self.id + ".png")
        }
    }
    
    func mapping(map: Map) {
        self.id <- map["id"]
        self.name <- map["name"]
        self.details <- map["details"]
        self.url <- map["url"]
        self.thumbUrl <- map["thumbUrl"]
        self.version <- map["version"]
        self.size <- map["size"]
        self.requiredAppVersion <- map["app"]
    }
    
    class func fromJson(json:String) -> DatabaseMetaInfo? {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "{" {
            return nil
        }
        return Mapper<DatabaseMetaInfo>().map(json)!
    }
    
    class func fromJsonArray(json:String) -> [DatabaseMetaInfo] {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "[" {
            return []
        }
        return Mapper<DatabaseMetaInfo>().mapArray(json)!
    }
}