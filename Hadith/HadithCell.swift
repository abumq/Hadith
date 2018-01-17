//
//  HadithCell.swift
//  Hadith
//
//  Created by Majid Khan on 31/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class HadithCell : CustomTableViewCell {
    
    @IBOutlet weak var gradeLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var excerptLabel: UILabel!
    
    func render(hadith : Hadith, highlightText:String = "") {
        titleLabel?.text = "Hadith " + String(hadith.hadithNumber)
        if highlightText.isEmpty {
            excerptLabel?.text = hadith.excerptText
        } else {
            
            let searchString = highlightText.lowercaseString
            let subject = hadith.customText != nil ? hadith.customText! : hadith.nonHTMLText
            var subjectString = subject.stringByReplacingOccurrencesOfString("\n", withString: " ")
            
            // Also include secondary ref for searching
            if (!self.isKindOfClass(HadithSearchResultCell.self) && hadith.secondaryRefs != nil) {
                subjectString = subjectString + " [Secondary Ref: " + hadith.collection!.mediumName + " "
                subjectString = subjectString + hadith.secondaryRefs!
                subjectString = subjectString + "]"
            }
            
            let list = searchString.characters.split{$0 == " "}.map(String.init)
            var pos = subjectString.lowercaseString.indexOf(searchString)
            if (pos >= 50) {
                subjectString = "..." + subjectString.substringFrom(pos - 50)
            } else {
                for word in list {
                    pos = subjectString.lowercaseString.indexOf(word)
                    if (pos >= 50) {
                        subjectString = "..." + subjectString.substringFrom(pos - 50)
                        // break at first occurance of word
                        // for example if search term is "three men" and subject is "two or three or four men"
                        // then we pos at occurance of "three" - 50
                        break
                    }
                }
            }
            
            
            let attributed = NSMutableAttributedString(string: subjectString)
            attributed.highlight(list)
            excerptLabel?.attributedText = attributed
        }
        gradeLabel?.attributedText = hadith.buildGradeAttributedText()
    }
    
}