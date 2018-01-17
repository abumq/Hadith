//
//  CustomViewController.swift
//  Hadith
//
//  Created by Majid Khan on 22/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class CustomViewController: UIViewController {
    
    var spinner : CustomActivityIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        spinner = CustomActivityIndicator(frame: self.view.frame)
        self.view.addSubview(spinner)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}