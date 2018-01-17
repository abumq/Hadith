//
//  UITextView.swift
//  Hadith
//
//  Created by Majid Khan on 3/08/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    func detectDirection() {
        if let text = self.text where !text.isEmpty {
            let tagschemes = NSArray(objects: NSLinguisticTagSchemeLanguage)
            let tagger = NSLinguisticTagger(tagSchemes: tagschemes as! [String], options: 0)
            tagger.string = text
            
            let language = tagger.tagAtIndex(0, scheme: NSLinguisticTagSchemeLanguage, tokenRange: nil, sentenceRange: nil)
            if language?.rangeOfString("he") != nil || language?.rangeOfString("ar") != nil || language?.rangeOfString("fa") != nil || language?.rangeOfString("ur") != nil {
                self.text = text.stringByReplacingOccurrencesOfString("\n", withString: "\n")
                self.textAlignment = .Right
                self.makeTextWritingDirectionRightToLeft(nil)
            }else{
                self.textAlignment = .Left
                self.makeTextWritingDirectionLeftToRight(nil)
            }
        }
    }
}