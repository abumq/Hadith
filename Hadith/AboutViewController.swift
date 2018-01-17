//
//  AboutViewController.swift
//  Hadith
//
//  Created by Majid Khan on 1/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class AboutViewController : UIViewController {
    
    let databaseManager = DatabaseManager.sharedInstance()
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        
        if let version : String = Utils.appVersion {
            self.versionLabel.text = String(format: "App Version: v%@.%@\nMaster Database Version: v0.%d", version, Utils.buildNumber, (databaseManager.masterDatabase?.version)!)
        }
        
        view.backgroundColor = UIColor.appThemeColorDark()
    }
    
}