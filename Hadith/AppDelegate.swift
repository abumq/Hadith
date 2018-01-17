//
//  AppDelegate.swift
//  Hadith
//
//  Created by Majid Khan on 24/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var accountManager = AccountManager.sharedInstance()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        configure()
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        configure()
        let urlString = url.absoluteString.stringByReplacingOccurrencesOfString("hadith://", withString: "http://muflihun.com/")
        var navigationController : UINavigationController?
        let tabController = self.window!.rootViewController as! MainViewController
        tabController.selectedIndex = 0
        
        for viewController in tabController.viewControllers! {
            let navController = viewController as! UINavigationController
            if navController.restorationIdentifier == "BrowseViewControllerNav" {
                navigationController = navController
            }
        }
        
        if navigationController != nil {
            
            // Pop view controllers if already have hadith detail page or anything in seq
            navigationController!.popToRootViewControllerAnimated(false)
            if let hadith = Utils.urlToHadith(urlString) {
                Utils.openQualifiedHadith(hadith, storyboard: self.window?.rootViewController?.storyboard, navigationController: navigationController)
            } else if let book = Utils.urlToBook(urlString) {
                Utils.openQualifiedBook(book, storyboard: self.window?.rootViewController?.storyboard, navigationController: navigationController)
            } else if let collection = Utils.urlToCollection(urlString) {
                Utils.openQualifiedCollection(collection, storyboard: self.window?.rootViewController?.storyboard, navigationController: navigationController)
            }
        }
        
        return true
    }

    
    func configure() {
        Fabric.with([Crashlytics.self, Answers.self])
        configureAppAppearance()
    }
    
    func applicationDidReceiveMemoryWarning() {
       Log.write("Memory warning")
    }
    
    private func configureAppAppearance() {
        window?.tintColor = UIColor.appThemeTintColor()
        UINavigationBar.appearance().tintColor = UIColor.appThemeTintColor()
        UINavigationBar.appearance().barTintColor = UIColor.appThemeBackground()
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        let databaseUpdateManager = DatabaseUpdateManager.sharedInstance()
        databaseUpdateManager.backgroundUpdateCompletedHandler = completionHandler
    }
}

