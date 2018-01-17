//
//  AccountManager.swift
//  Hadith
//
//  Created by Majid Khan on 13/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class AccountManager {
    
    let TokenVerifyURL = "http://muflihun.com/svc/versignintoken/"
    let TokenObtainURL = "http://muflihun.com/settings/"
    let TokenDefaultStatus = "Please enter a valid sign-in token.\nYou can obtain it from http://muflihun.com/settings/"
    var signInTokenVerificationResponse : SignInTokenVerificationResponse?
    var delegates : [String:AccountManagerDelegate] = [:]
    var loggedInMessage : String? = nil

    var isLoggedIn : Bool {
        get {
            return token != nil
                && signInTokenVerificationResponse != nil
                && signInTokenVerificationResponse!.error == false
                && signInTokenVerificationResponse!.email != nil;
        }
    }
    
    var email : String? {
        get {
            return isLoggedIn ? signInTokenVerificationResponse!.email : nil
        }
    }
    
    var token : String? {
        didSet {
            self.delegates.forEach({delegate -> () in delegate.1.tokenUpdated?() })

        }
    }
    
    required init() {
        token = SignInTokenSetting.load()
        checkSignInToken()
    }
    
    func updateToken(newToken : String) {
        token = newToken
        SignInTokenSetting.save(newToken)
        self.checkSignInToken()
    }
    
    func signOut() {
        updateToken("")
    }
    
    func checkSignInToken() {
        var responseMessage = "Verifying..."
        loggedInMessage = nil
        self.delegates.forEach({delegate -> () in delegate.1.accountUpdated?(responseMessage) })

        ({
            if self.token != "" && self.token != nil {
                let response = self.readTokenInfo(self.token!)
                if response == nil {
                    responseMessage = "Please check your internet connection"
                } else if response!.error == true && response!.message != nil {
                    responseMessage = "Error: " + response!.message!
                    if response?.errorCode == 3 {
                        responseMessage += "\n\nYou need to go to http://muflihun.com and sign in before you can use this token"
                    } else if response?.errorCode == 2 {
                        responseMessage += "\n\nObtain new token from \(self.TokenObtainURL)"
                    }
                } else if response!.error == true {
                    responseMessage = self.TokenDefaultStatus
                } else {
                    let identifier = response!.userId == nil ? response!.email! : response!.userId!;
                    responseMessage = "Signed in as " + response!.name! + " [\(identifier)]"
                    self.loggedInMessage = responseMessage
                }
                AccountManager.sharedInstance().signInTokenVerificationResponse = response
            } else {
                responseMessage = "Token could not be loaded"
                AccountManager.sharedInstance().signInTokenVerificationResponse = nil
            }
        }) ~> ({
            self.delegates.forEach({delegate -> () in delegate.1.accountUpdated?(self.token == nil || self.token == "" ? self.TokenDefaultStatus : responseMessage) })

        })
    }
    
    private func readTokenInfo(token : String) -> SignInTokenVerificationResponse? {
        do {
            var url = NSURL(string: TokenVerifyURL + token)
            if url == nil {
                // Invalid token
                url = NSURL(string: TokenVerifyURL + "")
            }
            let json = try String(contentsOfURL: url!)
            let response = SignInTokenVerificationResponse.fromJson(json)
            return response
        } catch {
            self.delegates.forEach({delegate -> () in delegate.1.accountUpdated?("Unexpected error while verifying token. Reset your token from the web.") })
            Log.write(error)
        }
        return nil
    }
    
    // MARK: Singleton
    struct Static {
        static var instance:AccountManager? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> AccountManager! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }
    
}