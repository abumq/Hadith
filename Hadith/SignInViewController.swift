//
//  SignInViewController.swift
//  Hadith
//
//  Created by Majid Khan on 17/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class SignInViewController : CustomTableViewController, UITextFieldDelegate, AccountManagerDelegate, QRCodeReaderViewControllerDelegate {
    
    var signinTokenStatus = "Verifying..."
    
    let accountManager = AccountManager.sharedInstance()
    
    var signingIn : Bool = false
    
    @IBOutlet var tableFooterView : UIView!
    @IBOutlet var signinTokenText : UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signinTokenText.delegate = self
        signinTokenText.text = accountManager.token
        accountManager.delegates[self.restorationIdentifier!] = self
        accountManager.checkSignInToken()
    }
        
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        accountManager.updateToken(textField.text!)
        return true
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        if cell?.reuseIdentifier == "SignOutCell" && accountManager.token?.characters.isEmpty == false {
            let alert = AlertViewWithCallback()
            alert.dismissWithClickedButtonIndex(1, animated: true)
            alert.title = "Are you sure you wish to sign out?"
            alert.alertViewStyle = UIAlertViewStyle.Default
            alert.addButtonWithTitle("Sign Out")
            alert.addButtonWithTitle("Cancel")
            alert.callback = { buttonIndex in
                if buttonIndex == 0 {
                    self.accountManager.signOut()
                    Analytics.logEvent(.SignOut)
                }
            }
            alert.show()
        } else if cell?.reuseIdentifier == "SignInCell" {
            accountManager.updateToken(signinTokenText.text!)
            accountManager.checkSignInToken()
            signingIn = true
        } else if cell?.reuseIdentifier == "ObtainTokenCell" {
            UIApplication.sharedApplication().openURL(NSURL(string: accountManager.TokenObtainURL)!)
        } else if cell?.reuseIdentifier == "ScanQRCodeCell" {
            scanQRCode(cell!)
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let defaultSize = UITableViewAutomaticDimension
        switch section {
        case 0:
            return accountManager.isLoggedIn ? 1.0 : defaultSize
        case 1:
            return accountManager.isLoggedIn ? 1.0 : defaultSize
        default:
            return defaultSize
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let defaultSize = UITableViewAutomaticDimension
        switch section {
        case 0:
            return accountManager.isLoggedIn ? 1.0 : defaultSize
        case 1:
            return accountManager.isLoggedIn ? 1.0 : defaultSize
        default:
            return defaultSize
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return accountManager.isLoggedIn ? 0 : 3
        case 1:
            return accountManager.isLoggedIn ? 0 : 1
        default:
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return accountManager.isLoggedIn ? nil : signinTokenStatus
        case 1:
            return accountManager.isLoggedIn ? nil : "Visit http://muflihun.com/settings/ for QR Code"
        case 2:
            return accountManager.isLoggedIn ? signinTokenStatus : nil
        default:
            return nil
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return accountManager.isLoggedIn ? 3 : 2
    }
    
    func accountUpdated(responseMessage : String) {
        self.signinTokenStatus = responseMessage
        tableView.reloadData()
        if !signingIn && accountManager.isLoggedIn {
            tableView.tableFooterView = nil
        } else {
            tableView.tableFooterView = self.tableFooterView
        }
        if signingIn && accountManager.isLoggedIn {
            Analytics.logEvent(.SignIn)
            
            // Go back
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func tokenUpdated() {
        signinTokenText.text = accountManager.token
    }
    
    func scanQRCode(sender : AnyObject) {
        if QRCodeReader.supportsMetadataObjectTypes() {
            let reader = createReader()
            reader.modalPresentationStyle = .FormSheet
            reader.delegate = self
            
            reader.completionBlock = { (result: QRCodeReaderResult?) in
                if let result = result {
                    Log.write("Completion with result: \(result.value) of type \(result.metadataType)")
                }
            }
            let navController = UINavigationController.init(rootViewController: reader)
            presentViewController(navController, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Error", message: "QR Code scanning is not supported by your device", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func readerDidCancel(reader: QRCodeReaderViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func reader(reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        self.dismissViewControllerAnimated(true) { [weak self] in
            self?.accountManager.updateToken(result.value)
            self?.accountManager.checkSignInToken()
            self?.signingIn = true
        }
    }
    
    private func createReader() -> QRCodeViewController {
        let builder = QRCodeViewControllerBuilder { builder in
            builder.reader          = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
            builder.showTorchButton = false
            builder.showSwitchCameraButton = false
            builder.showCancelButton = false
        }
        
        return QRCodeViewController(builder: builder)
    }
}