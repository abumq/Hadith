//
//  HadithPage.swift
//  Hadith
//
//  Created by Majid Khan on 1/07/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit


@objc protocol HadithPageDelegate : NSObjectProtocol {
    func UIChanged()
}

class HadithPage : CustomViewController {

    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var hadithReferenceTableHeight: NSLayoutConstraint!
    @IBOutlet weak var hadithReferenceTableContainer: UIView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var noteTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var languageSegmentControl: UISegmentedControl!
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var lblCollectionLabel: UILabel!
    @IBOutlet weak var lblBookAndHadithLabel: UILabel!
    @IBOutlet weak var lblGrade: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var lblNoteTextView: UILabel!
    @IBOutlet weak var noteTextView: UITextView!
    
    var hadithReferenceTable: HadithReferenceTable!
    var currentHadith : Hadith!
    var currentLanguage : Language!
    var currentFontSizeByLanguages : [String: CGFloat] = [:]
    var currentHadithByLanguages : HadithByLanguage = [:]
    var associatedNote : Note?
    
    var index : Int?
    
    weak var delegate : HadithPageDelegate?
    
    var defaultHadith : Hadith {
        get {
            return (currentHadithByLanguages.first?.1.hadith)!
        }
    }
    
    var defaultLanguage : Language {
        get {
            return (currentHadithByLanguages.first?.1.language)!
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "HadithReferenceTable" {
            hadithReferenceTable = segue.destinationViewController as! HadithReferenceTable
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:))))
        
        if !self.currentHadithByLanguages.isEmpty {
            hadithByLanguagesUpdated()
        }
    }
    
    func hadithByLanguagesUpdated() {
        self.languageSegmentControl.hidden = self.currentHadithByLanguages.count <= 1
        var languageIdx = 0;
        
        for languageHadithTuple in self.currentHadithByLanguages.values {
            let language = languageHadithTuple.language
            if (languageIdx > 1) {
                self.languageSegmentControl.insertSegmentWithTitle(language.name, atIndex: self.languageSegmentControl.numberOfSegments, animated: false)
            } else {
                self.languageSegmentControl.setTitle(language.name, forSegmentAtIndex: languageIdx)
            }
            languageIdx += 1
        }
        
        self.currentLanguage = self.defaultLanguage
        self.languageChanged(self.languageSegmentControl)
    }
    
    @IBAction func languageChanged(sender: UISegmentedControl) {
         let hadithLanguageTuple = currentHadithByLanguages[sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)!]
         self.currentLanguage = hadithLanguageTuple?.language
         self.currentHadith = hadithLanguageTuple?.hadith
         updateUI()
    }
    
    
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        updateTextViewHeight()
    }
    
    func updateTextViewHeight() {
        let contentSize = self.textView.sizeThatFits(self.textView.bounds.size)
        
        let height = contentSize.height
        textViewHeight.constant = max(height, 11)
    }
    
    func updateNoteTextViewHeight() {
        let contentSize = self.noteTextView.sizeThatFits(self.noteTextView.bounds.size)
        
        let height = contentSize.height
        noteTextViewHeight.constant = max(height, 11)
    }
    
    func onPinch(pinchGestRecognizer: UIPinchGestureRecognizer) {
        let velocity = pinchGestRecognizer.velocity
        let font = textView.font
        var pointSize = (velocity > 0 ? 1 : -1) * 1 + font!.pointSize
        if pointSize < 13 {
            pointSize = 13
        }
        if pointSize > 150 {
            pointSize = 150
        }
        textView.font = textView.font?.fontWithSize(pointSize)
        if currentLanguage != nil {
            currentFontSizeByLanguages[currentLanguage.name] = pointSize
        }
        updateTextViewHeight()
    }
   
    
    
    func updateUI() {
        if self.lblCollectionLabel == nil {
            // Flipping too fast?
            return
        }
        self.title = ""
        self.lblCollectionLabel.text = self.currentHadith.collection?.name
        self.lblBookAndHadithLabel.text = self.currentHadith.getRef(.BookWithNameOnly, collectionName: false)
        
        textView.attributedText = self.currentHadith.getAttributedText(self.currentFontSizeByLanguages[self.currentLanguage.name])
        
        
        lblGrade.attributedText = self.currentHadith.buildGradeAttributedText(20.0)
        updateTextViewHeight()
        hadithReferenceTable.list = []
        if (self.currentHadith.collection!.hasVolumes && self.currentHadith.collection!.hasBooks) {
            if let ref = self.currentHadith.getRef(.VolumeAndBook) {
                hadithReferenceTable.list.append(ref)
            }
        } else if (self.currentHadith.collection!.hasBooks) {
            if let ref = self.currentHadith.getRef(.BookWithNameOnly) {
                hadithReferenceTable.list.append(ref)
            }
        }
        if (self.currentHadith.collection!.hasBooks) {
            if let ref = self.currentHadith.getRef(.BookOnly) {
                hadithReferenceTable.list.append(ref)
            }
        }
        if let ref = self.currentHadith.getRef(.SecondaryRef) {
            hadithReferenceTable.list.append(ref)
        }
        if hadithReferenceTable.list.isEmpty {
            hadithReferenceTable.list.append(self.currentHadith.availableRef)
        }
        
        // Cross ref
        if currentHadith.links != nil {
            // Replace 4 slashes to no slash
            let links = currentHadith.links!.stringByReplacingOccurrencesOfString("\\\\", withString: "")
            hadithReferenceTable.crossRefList = CrossReference.fromJsonArray(links)
        } else {
            hadithReferenceTable.crossRefList = []
        }
        
        hadithReferenceTable.tableView.reloadData()
        
        let heightPerCell : CGFloat = 55.0
        hadithReferenceTableHeight.constant = (heightPerCell * CGFloat(hadithReferenceTable.list.count)) + heightPerCell;
        if !hadithReferenceTable.crossRefList.isEmpty {
            hadithReferenceTableHeight.constant += (heightPerCell * CGFloat(hadithReferenceTable.crossRefList.count));
        }
        lblNoteTextView.hidden = true
        if associatedNote != nil {
            noteTextView.text = associatedNote!.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            noteTextView.detectDirection()
            lblNoteTextView.hidden = noteTextView.text.isEmpty
            updateNoteTextViewHeight()
        }
        delegate?.UIChanged()
    }
}