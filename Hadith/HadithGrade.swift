//
//  HadithGrade.swift
//  Hadith
//
//  Created by Majid Khan on 29/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import UIKit

let UnknownGradeFlag : Int = 4194304
let UnknownGradeText : String = "Unknown"
let UnknownGradeColor : UIColor = UIColor.darkGrayColor()

class HadithGrade {
    
    static let AuthenticList = [1, 2, 16, 512, 2048, 4096, 8192, 16384, 32768, 65536, 2097152, 33554432]
    static var AllGrades = HadithGrade.allGrades()
    static let Unknown = HadithGrade()
    
    var flag : Int = UnknownGradeFlag
    var text : String = UnknownGradeText
    var color : UIColor = UnknownGradeColor
    
    convenience init() {
        self.init(flag: UnknownGradeFlag, text: UnknownGradeText, color: UnknownGradeColor)
    }
    
    init(flag:Int, text:String, color:UIColor) {
        self.flag = flag
        self.text = text
        self.color = color
    }
    
    class func allGrades() -> [HadithGrade] {
        var grades : [HadithGrade] = [HadithGrade]()
        
        grades += [HadithGrade()] // Unknown
        grades += [HadithGrade(flag: 1, text: "Sahih", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 2, text: "Hasan", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 4, text: "Da`eef", color: UIColor(hexString: "#ff0000"))]
        grades += [HadithGrade(flag: 8, text: "Moudu`", color: UIColor(hexString: "#ff0000"))]
        grades += [HadithGrade(flag: 16, text: "Hasan Sahih", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 32, text: "Munkar", color: UIColor(hexString: "#f15757"))]
        grades += [HadithGrade(flag: 64, text: "Shadhdh", color: UIColor(hexString: "#f15757"))]
        grades += [HadithGrade(flag: 128, text: "Mauquf", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 256, text: "Maqtu`", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 512, text: "Sahih in Chain", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 1024, text: "Da`eef Jiddan", color: UIColor(hexString: "#ff0000"))]
        grades += [HadithGrade(flag: 2048, text: "Hasan in Chain", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 4096, text: "Sahih li-ghairih", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 8192, text: "Marfu`", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 16384, text: "Mutawatir", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 32768, text: "Mursal", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 65536, text: "Hasan li-ghairih", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 131072, text: "No chain found (Al-Albani)", color: UIColor(hexString: "#999999"))]
        grades += [HadithGrade(flag: 262144, text: "Chain is da`eef (Al-Albani)", color: UIColor(hexString: "#ff0000"))]
        grades += [HadithGrade(flag: 524288, text: "Hasan Gharib", color: UIColor(hexString: "#FF7400"))]
        grades += [HadithGrade(flag: 1048576, text: "Qudsi", color: UIColor(hexString: "#00ff00"))]
        grades += [HadithGrade(flag: 2097152, text: "Sahih Mouquf", color: UIColor(hexString: "#6B8E23"))]
        grades += [HadithGrade(flag: 8388608, text: "Gharib", color: UIColor(hexString: "#C8B560"))]
        grades += [HadithGrade(flag: 16777216, text: "Munqati`", color: UIColor(hexString: "#ff0000"))]
        grades += [HadithGrade(flag: 33554432, text: "Sahih (Al-Albani)", color: UIColor(hexString: "#6B8E23"))]
        return grades
    }
}