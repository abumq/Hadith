//
//  Utils.swift
//  Hadith
//
//  Created by Majid Khan on 2/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite

class Utils {
    
    static var appVersion : String {
        get {
            return NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
        }
    }
    static var buildNumber : String {
        get {
            return NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String
        }
    }
    class func bytesToHumanReadable(bytes: Double) -> String {
        if (bytes < 0) {
            return "Unknown bytes";
        } else if (bytes < 1024) {
            return String(bytes) + " B";
        }
        let exp = Int(log(Double(bytes)) / log(1024))
        
        var units : [String] = ["k", "M", "G", "T", "P"]
        let unit = units[exp - 1]
        let value = Float(Double(bytes) / pow(1024, Double(exp)))
        let result = String(format: value == floor(value) ? "%.0f %@B" : "%.1f %@B", value, unit)
        return result;
    }
    
    class func getFileSize(filename : String) -> Double {
        do {
            let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(filename)
            if let fileSize = attributes[NSFileSize] {
                return Double(fileSize as! NSNumber)
            }
        } catch {
            
        }
        return -1
    }
    
    class func databaseTableExists(tableName: String, connection : Connection) -> Bool {
        let count:Int64 = connection.scalar(
            "SELECT EXISTS(SELECT name FROM sqlite_master WHERE name = ?)", tableName
            ) as! Int64
        return count > 0
    }
    
    
    class func moveFromBundleToDocument(file: String, destName: String) {
        let fm = NSFileManager.defaultManager()
        var fileSize = 0
        do {
            let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(file)
            fileSize = fileAttributes[NSFileSize] as! Int
        }
        catch {
            //fileSize = 0
        }
        if !(fm.fileExistsAtPath(file)) || fileSize == 0 {
            guard let mainBundlePath = NSBundle.mainBundle().resourcePath else { return }
            let from = (mainBundlePath as NSString).stringByAppendingPathComponent(destName)
            if (!fm.fileExistsAtPath(from)) {
                Log.write("[\(destName)] does not exist")
                return
            }
            do {
                if (fm.fileExistsAtPath(file)) {
                    try fm.removeItemAtPath(file)
                }
                Log.write("Setting up [\(destName)]")
                try fm.copyItemAtPath(from, toPath: file)
            } catch let error as NSError {
                Log.write("Error - \(error.localizedDescription)")
                return
            }
        }
    }
    
    
    class func openQualifiedCollection(collection : Collection, storyboard: UIStoryboard?, navigationController : UINavigationController?) {
        let bookViewController = storyboard?.instantiateViewControllerWithIdentifier("BookViewController") as! BookViewController
        bookViewController.collection = collection
        navigationController?.pushViewController(bookViewController, animated: false)
    }
    
    class func openQualifiedBook(book : Book, storyboard: UIStoryboard?, navigationController : UINavigationController?) {
        Utils.openQualifiedCollection(book.collection!, storyboard: storyboard, navigationController: navigationController)
        let hadithListViewController = storyboard?.instantiateViewControllerWithIdentifier("HadithListViewController") as! HadithListViewController
        hadithListViewController.collection = book.collection!
        hadithListViewController.book = book
        navigationController?.pushViewController(hadithListViewController, animated: false)
    }
    
    class func openQualifiedHadith(hadith : Hadith, storyboard: UIStoryboard?, navigationController : UINavigationController?) {
        if hadith.collection!.hasBooks {
            Utils.openQualifiedBook(hadith.book!, storyboard: storyboard, navigationController: navigationController)
        } else {
            Utils.openQualifiedCollection(hadith.collection!, storyboard: storyboard, navigationController: navigationController)
        }
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("HadithDetailsViewController") as! HadithDetailsViewController
        viewController.initializeFrontPage(hadith)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    class func urlToCollection(url : String) -> Collection? {
        let collectionManager = CollectionManager.sharedInstance()
        var collection : Collection?
        if url.containsString("//muflihun.com") {
            let parts = url.characters.split{$0 == "/"}.map(String.init)
            if parts.count > 2 {
                let collectionName = parts[2]
                for c in collectionManager.collections {
                    if c.shortName == collectionName {
                        collection = c
                        break
                    }
                }
            }
        }
        
        return collection
    }
    
    class func urlToBook(url : String) -> Book? {
        let collectionManager = CollectionManager.sharedInstance()
        let collection = Utils.urlToCollection(url);
        if collection == nil || !collection!.hasBooks {
            return nil
        }
        var book : Book?
        if url.containsString("//muflihun.com") {
            let parts = url.characters.split{$0 == "/"}.map(String.init)
            if parts.count > 3 {
                if let bookNumber = Int(parts[3]) {
                    book = collectionManager.loadBook(collection!, bookNumber: bookNumber)
                }
            }
        }
        
        return book
    }
    
    class func urlToHadith(url : String) -> Hadith? {
        let collectionManager = CollectionManager.sharedInstance()
        let collection = Utils.urlToCollection(url);
        if collection == nil {
            return nil
        }
        let book : Book? = collection!.hasBooks ? Utils.urlToBook(url) : nil;
        if collection!.hasBooks && book == nil {
            return nil
        }
        var hadith : Hadith?
        if url.containsString("//muflihun.com") {
            let parts = url.characters.split{$0 == "/"}.map(String.init)
            var bookNumber : Int?
            var hadithNumber : String?
            if collection!.hasBooks && parts.count > 4 {
                bookNumber = Int(parts[3])
                hadithNumber = parts[4]
            } else if !collection!.hasBooks && parts.count > 3 {
                hadithNumber = parts[3]
            }
            
            // Finally query
            if collection!.hasBooks && bookNumber != nil && hadithNumber != nil {
                hadith = collectionManager.loadHadith(collection!, volumeNumber: nil, bookNumber: bookNumber, hadithNumber: hadithNumber!)
                
            } else if !collection!.hasBooks && hadithNumber != nil {
                hadith = collectionManager.loadHadith(collection!, volumeNumber: nil, bookNumber: nil, hadithNumber: hadithNumber!)
            }
        }
        
        return hadith
    }
}