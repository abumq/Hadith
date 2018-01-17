//
//  WriteNoteViewController.swift
//  Hadith
//
//  Created by Majid Khan on 5/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit


class WriteNoteViewController : CustomViewController, UITextViewDelegate {
    
    var noteManager = NoteManager.sharedInstance()
    
    @IBOutlet var titleText : UITextField!
    @IBOutlet var detailText : UITextView!
    @IBOutlet weak var detailTextHeight: NSLayoutConstraint!
    var showHadithButton : UIBarButtonItem!
    
    var hadith : Hadith!
    var note : Note?
    
    override func viewDidLoad() {
        if note != nil {
            hadith = note!.hadith!
            title = "Edit Note"
        } else {
            title = "Write Note"
        }
        if hadith != nil {
            if noteManager.hasNote(hadith!) {
                note = noteManager.getNote(hadith!)
            }
        }
        
        if note != nil {
            titleText.text = note!.title
            detailText.text = note!.text
            detailText.detectDirection()
        }
        detailText.layer.borderWidth = 1.0
        detailText.layer.borderColor = UIColor(hexString:"#cccccc").CGColor
        detailText.layer.cornerRadius = 8;
        updateNoteTextViewHeight()
        detailText.delegate = self
    }
    
    func textViewDidChange(textView: UITextView) {
        updateNoteTextViewHeight()
    }
    
    func updateNoteTextViewHeight() {
        let contentSize = self.detailText.sizeThatFits(self.detailText.bounds.size)
        
        let height = contentSize.height + (view.frame.height / 2.0)
        detailTextHeight.constant = max(height, 11)
    }
    
    @IBAction func onCancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    @IBAction func onSave(sender: UIBarButtonItem) {
        if hadith != nil {
            if note != nil {
                noteManager.update(note!, title: titleText.text!, text: detailText.text)
            } else {
                noteManager.add(titleText.text!, text: detailText.text, hadith: hadith)
                Analytics.logEvent(.AddNote, value: hadith.availableRef)
            }
        }
        onCancel(sender)
    }
    
}