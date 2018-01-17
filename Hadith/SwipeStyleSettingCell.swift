//
//  SwipeSettingCell.swift
//  Hadith
//
//  Created by Majid Khan on 17/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class SwipeSettingCell : CustomTableViewCell {
    
    var setting = SwipeStyleSetting.Page
    
    func updateCheck() {
        self.accessoryType = setting == self.setting ? .Checkmark : .None
    }
}