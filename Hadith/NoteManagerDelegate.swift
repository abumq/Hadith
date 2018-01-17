//
//  NoteManagerDelegate.swift
//  Hadith
//
//  Created by Majid Khan on 6/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation


@objc protocol NoteManagerDelegate : NSObjectProtocol {
    optional func notesLoaded()
    optional func notesAddFailed(message : String)
    optional func syncFailed(message : String)
    optional func syncCompleted()
}