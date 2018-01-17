//
//  QRCodeViewController.swift
//  Hadith
//
//  Created by Majid Khan on 4/08/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class QRCodeViewController : QRCodeReaderViewController {
    override func viewDidLoad() {
        title = "Scan QR Code"
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(self.readerDidCancel))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    func readerDidCancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}