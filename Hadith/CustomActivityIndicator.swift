//
//  CustomActivityIndicator.swift
//  Hadith
//
//  Created by Majid Khan on 24/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

// Note: Do not override this as CustomUIView since we don't want background
// image for activity indicator
class CustomActivityIndicator : UIView {
    var spinner : UIActivityIndicatorView!
    var spinnerLabel : UILabel!
    
    override init(frame: CGRect) {
        let spinnerSize = (width: 150, height: 90)
        super.init(frame: CGRect(
                x: 0,
                y: 0,
                width: spinnerSize.width,
                height: spinnerSize.height)
        )
        self.center = CGPointMake(frame.size.width  / 2, frame.size.height / 2);
        self.backgroundColor = UIColor.darkGrayColor()
        self.alpha = 0.8
        self.layer.cornerRadius = 8.0
        self.clipsToBounds = true
        spinner = UIActivityIndicatorView()
        spinner.center = CGPointMake(25, self.frame.size.height / 2);
        spinner.hidesWhenStopped = true
        self.addSubview(spinner)
        
        spinnerLabel = UILabel(frame:self.frame)
        spinnerLabel.center = CGPointMake(125, self.frame.size.height / 2);
        spinnerLabel.textColor = UIColor.lightGrayColor()
        spinnerLabel.text = "Loading..."
        self.addSubview(spinnerLabel)
        self.hidden = true
    }
    
    func updateSpinnerLabel(text : String) {
        spinnerLabel.text = text
    }
    
    func startAnimating() {
        self.hidden = false
        spinner.startAnimating()
    }
    
    func stopAnimating() {
        spinner.stopAnimating()
        if spinner.hidesWhenStopped {
            self.hidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}