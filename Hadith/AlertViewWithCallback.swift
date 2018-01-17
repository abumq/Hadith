//
//  AlertViewWithCallback.swift
//  Hadith
//
//  Created by Majid Khan on 27/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class AlertViewWithCallback : UIAlertView, UIAlertViewDelegate {
    
    typealias AlertViewCallback = (Int -> Void)
    
    var callback : AlertViewCallback?
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        callback?(buttonIndex)
    }
    
    override func show() {
        self.delegate = self
        super.show()
    }
}