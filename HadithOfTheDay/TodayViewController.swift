//
//  TodayViewController.swift
//  HadithOfTheDay
//
//  Created by Majid Khan on 20/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import UIKit
import NotificationCenter
import ObjectMapper

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var hadithTextControl : UILabel!
    
    var hadithToday : HadithToday?
    var tapRecognizer : UITapGestureRecognizer!
    
    func fetchHadithOfTheDay() {
        do {
            let json = try String(contentsOfURL: NSURL(string: "http://muflihun.com/svc/hadithtoday")!)
            self.hadithToday = HadithToday.fromJson(json)
            if self.hadithToday != nil {
                self.hadithTextControl.text = self.hadithToday!.text
                self.hadithTextControl.text! += " [" + self.hadithToday!.ref + "]"
            }
        } catch {
            print(error)
            if self.hadithToday == nil {
                self.hadithTextControl.text = "Failed to load"
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(TodayViewController.onTap(_:)))
        view.addGestureRecognizer(tapRecognizer)

        self.hadithTextControl.textColor = UIColor.whiteColor()
        if self.hadithToday == nil {
            self.hadithTextControl.text = "Loading..."
        }
        self.fetchHadithOfTheDay()
    }
    
    func onTap(sender: AnyObject) {
        if hadithToday != nil {
            extensionContext?.openURL(NSURL(string: hadithToday!.link.stringByReplacingOccurrencesOfString("http://muflihun.com/", withString: "hadith://"))!, completionHandler: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        let beforeUpdateText = self.hadithToday?.text
        self.fetchHadithOfTheDay()
        if self.hadithToday != nil && self.hadithToday!.text != beforeUpdateText {
            completionHandler(NCUpdateResult.NewData)
        } else {
            completionHandler(NCUpdateResult.NoData)

        }
    }
    
}
