//
//  Hadith.swift
//  Hadith
//
//  Created by Majid Khan on 29/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import SQLite

class Hadith : BaseModel, Equatable {
    enum ReferenceType {
        case VolumeAndBook
        case VolumeOnly
        case BookWithNameOnly
        case BookOnly
        case SecondaryRef
    }
    static let TableName = "Hadith"
    struct Column {
        static let id = Expression<Int64>("id")
        static let language = Expression<Int>("language_id")
        static let collectionNumber = Expression<Int>("collection_id")
        static let volumeNumber = Expression<Int?>("volume")
        static let bookNumber = Expression<Int?>("book")
        static let hadithNumber = Expression<String>("number")
        static let text = Expression<String>("text")
        static let grade = Expression<Int>("grade")
        static let tags = Expression<String?>("tags")
        static let refTags = Expression<String?>("ref_tags")
        static let references = Expression<String?>("refs")
        static let links = Expression<String?>("links")
        struct Cast {
            static let hadithNumberInt = cast(Hadith.Column.hadithNumber) as Expression<Int>
        }
    }
    
    
    var id : Int64 = 0
    var languageId : Int = 1
    var collectionNumber : Int = 0
    var volumeNumber : Int? = nil
    var bookNumber : Int? = nil
    var hadithNumber : String = "0"
    var text : String = ""
    var grade : Int = 0
    var tags : String? = nil
    var refTags : String? = nil
    var references : String? = nil
    var links : String? = nil
    
    // Non-fields
    var hadithGrades : [HadithGrade] = [HadithGrade](arrayLiteral: HadithGrade())
    var collection : Collection?
    var book : Book?
    
    var customText : String? = nil
    var fontSize : Int?
    var direction : Language.Direction?
    var fontFamily : String?
    
    var secondaryRefs : String? {
        if references != nil {
            let ref = references?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if ref != "" && ref != hadithNumber {
                return ref
            }
        }
        return nil
    }
    var hadithLink : String {
        get {
            if (self.collection != nil) {
                let baseURL = "http://muflihun.com/"
                let collectionURLPath = self.collection!.shortName + "/"
                var bookNumberURLPath = ""
                if (self.book != nil) {
                    bookNumberURLPath = String(self.book!.bookNumber) + "/"
                }
                return baseURL + collectionURLPath + bookNumberURLPath + self.hadithNumber
            }
            return ""
        }
    }
    
    var availableRef : String {
        var availableRef = self.secondaryRefs != nil ? self.getRef(.SecondaryRef) : nil
        if (availableRef == nil) {
            availableRef = self.getRef(.VolumeAndBook)
        }
        if (availableRef == nil) {
            availableRef = self.getRef(.BookWithNameOnly)
        }
        if (availableRef == nil) {
            availableRef = self.getRef(.BookOnly)
        }
        if (availableRef == nil) {
            availableRef = self.getRef(.VolumeOnly)
        }
        if (availableRef == nil) {
            availableRef = self.collection!.mediumName
        }
        return availableRef!
    }
    
    var excerptText : String {
        var excerptText = self.nonHTMLText;
        excerptText = excerptText.stringByReplacingOccurrencesOfString("\n", withString: " ")
        return excerptText.characters.count > 150 ? excerptText.substringTo(150) + " ..." : excerptText
    }
    
    var nonHTMLText : String {
        var result = self.text
        result = result.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
        
        // Remove all the tags
        let tags = ["b", "br", "<br />", "<br/>", "sup", "footnotes", "blockquote"]
        tags.forEach({tag in
            if tag.hasSuffix("/>") {
                result = result.stringByReplacingOccurrencesOfString(tag, withString: " ")
            } else {
                result = result.stringByReplacingOccurrencesOfString("<" + tag + ">", withString: "")
                result = result.stringByReplacingOccurrencesOfString("</" + tag + ">", withString: "")
            }
        })
        return result
    }
    
    func getAttributedText(fontSizeOverride : CGFloat?) -> NSAttributedString {
        var text = self.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        text = text.stringByReplacingOccurrencesOfString("\n", withString: "<br>")
        text = text.stringByReplacingOccurrencesOfString("<br>", withString: "\n")
        text = text.stringByReplacingOccurrencesOfString("<br/>", withString: "\n")
        text = text.stringByReplacingOccurrencesOfString("<br />", withString: "\n")
        text = text.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
        text = text.stringByReplacingOccurrencesOfString("<blockquote>", withString: "")
        text = text.stringByReplacingOccurrencesOfString("</blockquote>", withString: "")
        var font : UIFont!
        var textAttr = [String : NSObject]()

        
        var fontSize : CGFloat
        if fontSizeOverride != nil {
            fontSize = fontSizeOverride!
        } else if self.fontSize != nil {
            fontSize = CGFloat(self.fontSize!)
        } else {
            fontSize = CGFloat(Language.defaultFontSize)
        }
        
        if let fontFamily = self.fontFamily {
            font = UIFont(name: fontFamily, size: fontSize)
        } else {
            font = UIFont.systemFontOfSize(fontSize)
        }
        
        textAttr[NSFontAttributeName] = font
        
        let resultParagraphStyle = NSMutableParagraphStyle()
        if self.direction != nil {
            switch self.direction! {
            case .LeftToRight:
                resultParagraphStyle.alignment = .Left
            case .RightToLeft:
                resultParagraphStyle.alignment = .Right
            }
        }
        textAttr[NSParagraphStyleAttributeName] = resultParagraphStyle
        var result = NSAttributedString(string: text, attributes: textAttr)
        
        var boldAttr = [String : NSObject]()
        // TODO: Bold font
        boldAttr[NSFontAttributeName] = font
        
        var supAttr = [String : NSObject]()
        supAttr[NSForegroundColorAttributeName] = UIColor.lightGrayColor()
        supAttr[NSFontAttributeName] = font
        supAttr[NSBaselineOffsetAttributeName] = 10
        
        var footNotesAttr = [String : NSObject]()
        footNotesAttr[NSForegroundColorAttributeName] = UIColor.darkGrayColor()
        footNotesAttr[NSFontAttributeName] = font
        
        result = result.replaceHTMLTag("sup", withAttributes: supAttr)
        result = result.replaceHTMLTag("footnotes", withAttributes: footNotesAttr)
        result = result.replaceHTMLTag("b", withAttributes: boldAttr)
        
        return result
    }
    
    func getRef(referenceType:ReferenceType, collectionName : Bool = true) -> String? {
        if (self.collection == nil) {
            return nil
        }
        var prefix : String = collectionName ? self.collection!.name + ", " : ""
        switch referenceType {
        case .VolumeAndBook:
            if (self.collection!.hasVolumes == true) {
                prefix = prefix + "Vol. " + String(self.volumeNumber!) + ", "
            }
            if (self.collection!.hasBooks == true) {
                prefix = prefix + "Book of " + self.book!.name + ", "
            }
            prefix = prefix + "Hadith no. " + String(self.hadithNumber)
            
        case .VolumeOnly:
            if (self.collection?.hasVolumes == true) {
                prefix = prefix + "Vol. " + String(self.volumeNumber!) + ", "
            }
            prefix = prefix + "Hadith no. " + String(self.hadithNumber)
        case .BookWithNameOnly:
            if (self.collection!.hasBooks == true) {
                prefix = prefix + "Book of " + self.book!.name + ", "
            }
            prefix = prefix + "Hadith no. " + String(self.hadithNumber)
        case .BookOnly:
            if (self.collection!.hasBooks == true) {
                prefix = prefix + "Book. " + String(self.bookNumber!) + ", "
            }
            prefix = prefix + "Hadith no. " + String(self.hadithNumber)
        case .SecondaryRef:
            if (self.secondaryRefs != nil) {
                prefix = prefix + "no. " + self.secondaryRefs!
            } else {
                return nil
            }
        }
        
        return prefix
    }
    
    override func buildFromRow(row: Row) -> Hadith {
        self.id = row[Column.id]
        self.languageId = row[Column.language]
        self.collectionNumber = row[Column.collectionNumber]
        self.volumeNumber = row[Column.volumeNumber]
        self.bookNumber = row[Column.bookNumber]
        self.hadithNumber = row[Column.hadithNumber]
        self.text = row[Column.text]
        self.grade = row[Column.grade]
        self.tags = row[Column.tags]
        self.refTags = row[Column.refTags]
        self.references = row[Column.references]
        self.links = row[Column.links]
        self.hadithGrades.removeAll()
        for hadithGrade in HadithGrade.AllGrades {
            if (self.grade & hadithGrade.flag != 0) {
                self.hadithGrades.append(hadithGrade)
            }
        }
        // Add unknown if no grade found
        if self.hadithGrades.isEmpty {
            self.hadithGrades.append(HadithGrade.Unknown)
        }
        return self
    }
    
    func buildGradeAttributedText() -> NSMutableAttributedString {
        return self.buildGradeAttributedText(14.0)
    }
    
    func buildGradeAttributedText(fontSize : CGFloat) -> NSMutableAttributedString {
        let gradeString = NSMutableAttributedString(string: "")
        for hadithGrade in self.hadithGrades {
            var attr = [String : NSObject]()
            attr[NSForegroundColorAttributeName] = UIColor.whiteColor()
            attr[NSBackgroundColorAttributeName] = hadithGrade.color
            attr[NSFontAttributeName] = UIFont.systemFontOfSize(fontSize)
            gradeString.appendAttributedString(NSAttributedString(string: hadithGrade.text, attributes: attr))
            if self.hadithGrades.count > 1 {
                // Empty space
                gradeString.appendAttributedString(NSAttributedString(string: " ", attributes: [:]))
            }
        }
        return gradeString
    }
}

func ==(lhs: Hadith, rhs: Hadith) -> Bool {
    return lhs.collectionNumber == rhs.collectionNumber
        && lhs.volumeNumber == rhs.volumeNumber
        && lhs.bookNumber == rhs.bookNumber
        && lhs.hadithNumber == rhs.hadithNumber
}