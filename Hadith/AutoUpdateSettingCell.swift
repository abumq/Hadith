//
//  AutoUpdateSettingCell.swift
//  Hadith
//
//  Created by Majid Khan on 6/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class AutoUpdateSettingCell : CustomTableViewCell {
    
    var setting : AutoUpdateSetting = AutoUpdateSetting.WiFi
    
    func updateCheck() {
        self.accessoryType = setting == self.setting ? .Checkmark : .None
    }
}