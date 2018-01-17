//
//  TableViewControllerWithEmptyDataHandler.swift
//  Hadith
//
//  Created by Majid Khan on 19/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import DZNEmptyDataSet
class TableViewControllerWithEmptyDataHandler : CustomTableViewController {
    var emptyDataInfo : EmptyDataInfo = ("", "", .None, false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func getDefaultEmptyData(type: EmptyDataDefaultType, args: String...) -> EmptyDataInfo {
        switch type {
        case .NoData:
            return ("No Data Found", "Please download to continue.", .Data, true)
        case .AppVersion:
            return ("Update Your App", String(format: "Please update your app from AppStore.\nMinimum app version required: v%@", args), .Data, false)
        }
    }
}
extension TableViewControllerWithEmptyDataHandler : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        let updatesViewController : UpdatesViewController = storyboard?.instantiateViewControllerWithIdentifier("UpdatesViewController") as! UpdatesViewController
        navigationController?.pushViewController(updatesViewController, animated: true)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        if emptyDataInfo.hasButton {
            var attr = [String : NSObject]()
            attr[NSForegroundColorAttributeName] = UIColor.appThemeColorLight()
            attr[NSFontAttributeName] = UIFont.boldSystemFontOfSize(17.0)
            return NSAttributedString(string: "Continue", attributes: attr)
        }
        return NSAttributedString()
    }
    
    func emptyDataSetWillAppear(scrollView: UIScrollView!) {
        tableView.separatorStyle = .None
    }
    
    func emptyDataSetWillDisappear(scrollView: UIScrollView!) {
        tableView.separatorStyle = .SingleLine
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: emptyDataInfo.imageName.rawValue)
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var attr = [String : NSObject]()
        attr[NSForegroundColorAttributeName] = UIColor.darkGrayColor()
        attr[NSFontAttributeName] = UIFont.systemFontOfSize(18.0)
        return NSAttributedString(string: emptyDataInfo.title, attributes: attr)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var attr = [String : NSObject]()
        attr[NSForegroundColorAttributeName] = UIColor.darkGrayColor()
        attr[NSFontAttributeName] = UIFont.systemFontOfSize(14.0)
        return NSAttributedString(string: emptyDataInfo.description, attributes: attr)
    }
}