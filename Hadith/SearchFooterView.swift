//
//  SearchFooterView.swift
//  Hadith
//
//  Created by Majid Khan on 19/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

@objc protocol SearchFooterDelegate : NSObjectProtocol {
    func nextPage()
    func prevPage()
    func firstPage()
}
class SearchFooterView : UIView {
    
    weak var delegate : SearchFooterDelegate?
    
    @IBOutlet weak var firstPageButton : UIBarButtonItem!
    @IBOutlet weak var nextPageButton : UIBarButtonItem!
    @IBOutlet weak var prevPageButton : UIBarButtonItem!
    
    @IBAction func changePage(sender:UIBarButtonItem!) {
        if sender == nextPageButton {
            delegate?.nextPage()
        } else if sender == prevPageButton {
            delegate?.prevPage()
        } else if sender == firstPageButton {
            delegate?.firstPage()
        }
    }
}