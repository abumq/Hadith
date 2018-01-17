//
//  CollectionCell.swift
//  Hadith
//
//  Created by Majid Khan on 17/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit
class CollectionCell : CustomTableViewCell {
    
    let defaultFontFamily : String = "DroidArabicNaskh"
    var correspondingDatabaseMetaInfo : DatabaseMetaInfo?
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var hadithCount: UILabel!
    @IBOutlet weak var englishTitle: UILabel!
    @IBOutlet weak var arabicTitle: UILabel!
    
    func render() {
        if arabicTitle.text == nil {
            arabicTitle.hidden = true
        } else {
            arabicTitle.hidden = false
            arabicTitle.font = UIFont(name: defaultFontFamily, size: 18.0)

        }
    }
}