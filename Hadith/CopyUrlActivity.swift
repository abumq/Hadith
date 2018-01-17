//
//  CopyUrlActivity.swift
//  Hadith
//
//  Created by Majid Khan on 2/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class CopyUrlActivity: UIActivity {
    var url : NSURL!
    init(url : NSURL) {
        self.url = url
    }
    override func activityTitle() -> String? {
        return "Copy URL"
    }
    override func activityImage() -> UIImage? {
        return UIImage(named: "copy-url")
    }
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        for a in activityItems {
            if a is NSURL  {
                return true
            }
        }
        return false
    }
    
    override func performActivity() {
        UIPasteboard.generalPasteboard().string = url.absoluteString
    }
}