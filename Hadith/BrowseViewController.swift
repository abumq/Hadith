//
//  BrowseViewController.swift
//  Hadith
//
//  Created by Majid Khan on 29/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

class BrowseViewController : TableViewControllerWithEmptyDataHandler {
    
    let collectionManager = CollectionManager.sharedInstance()
    let databaseManager = DatabaseManager.sharedInstance()
    
    override func viewDidLoad() {
        tableView.separatorStyle = .None
        emptyDataInfo.imageName = .Data
        emptyDataInfo.hasButton = true
        super.viewDidLoad()
                
        let collectionCellNib = UINib(nibName: "CollectionCell", bundle: nil)
        tableView.registerNib(collectionCellNib, forCellReuseIdentifier: "CollectionCell")
        collectionManager.delegates[self.restorationIdentifier!] = self
        
        collectionManager.loadData()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 150.0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionManager.collections.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CollectionCell") as! CollectionCell
        let collection = collectionManager.collections[indexPath.row]
        cell.correspondingDatabaseMetaInfo = databaseManager.databaseMetaInfo[collection.identifier]
        cell.englishTitle?.text = collection.name
        cell.arabicTitle?.text = collection.arabicName
        cell.hadithCount?.text = (collection.totalHadiths > 0 ? String(collection.totalHadiths) : "No") + " Hadith" + (collection.totalHadiths > 1 ? "s" : "")
        updateThumbnailForCell(cell)
        
        return cell
    }
    
    func updateThumbnailForCell(collectionCell: CollectionCell) {
        if collectionCell.correspondingDatabaseMetaInfo != nil && collectionCell.correspondingDatabaseMetaInfo?.thumbnailFile != nil {
            collectionCell.icon?.image = UIImage(contentsOfFile: collectionCell.correspondingDatabaseMetaInfo!.thumbnailFile!)
        } else {
            collectionCell.icon?.image = UIImage(named: CollectionManager.defaultThumbAssetName)
        }
        collectionCell.render()

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let collection = collectionManager.collections[indexPath.row]
        var viewController : UIViewController!
        if (collection.hasBooks) {
            viewController = (storyboard?.instantiateViewControllerWithIdentifier("BookViewController") as? BookViewController)!
            (viewController as! BookViewController).collection = collection
        } else {
            viewController = (storyboard?.instantiateViewControllerWithIdentifier("HadithListViewController") as? HadithListViewController)!
            (viewController as! HadithListViewController).collection = collection
        }
        Analytics.logEvent(.OpenCollection, value: collection.name)
        if (navigationController?.visibleViewController?.restorationIdentifier != viewController.restorationIdentifier) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension BrowseViewController : CollectionManagerDelegate {
    func dataLoaded(emptyDataTitle: String, emptyDataDescription: String) {
        emptyDataInfo.title = emptyDataTitle
        emptyDataInfo.description = emptyDataDescription
        tableView.reloadData()
    }
    
    func thumbnailUpdated(identifier: String) {
        for cell in tableView.visibleCells {
            let collectionCell = cell as! CollectionCell
            if collectionCell.correspondingDatabaseMetaInfo?.id == identifier {
                updateThumbnailForCell(collectionCell)
            }
        }
    }
}