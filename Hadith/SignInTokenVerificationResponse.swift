//
//  SignInTokenVerificationResponse.swift
//  Hadith
//
//  Created by Majid Khan on 13/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation


import ObjectMapper

class SignInTokenVerificationResponse : NSObject, Mappable  {
    var errorCode : Int! = -1
    var message : String?
    var userId : String?
    var name : String?
    var email : String?
    
    var error : Bool {
        get {
            return errorCode != -1
        }
    }
    
    override init() {
    }
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        self.errorCode <- map["errorCode"]
        self.message <- map["message"]
        self.userId <- map["userId"]
        self.name <- map["name"]
        self.email <- map["email"]
    }
    
    class func fromJson(json:String) -> SignInTokenVerificationResponse? {
        if json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.first != "{"
            || json.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.last != "}" {
            return nil
        }
        return Mapper<SignInTokenVerificationResponse>().map(json)!
    }
}