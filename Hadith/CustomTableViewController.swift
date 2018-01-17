//
//  CustomTableViewController.swift
//  Hadith
//
//  Created by Majid Khan on 18/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class CustomTableViewController: UITableViewController {
    var spinner : CustomActivityIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let background = UIColor.appThemeBackground()
        //tableView.backgroundColor = background
        
        spinner = CustomActivityIndicator(frame: tableView.frame)
        tableView.addSubview(spinner)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}