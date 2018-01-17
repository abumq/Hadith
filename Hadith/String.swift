//
//  String.swift
//  Hadith
//
//  Created by Majid Khan on 9/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

extension String {
    
	func indexOf(string:String)->Int {
		var pos = -1
		if let range = self.rangeOfString(string) {
			if !range.isEmpty {
				pos = self.startIndex.distanceTo(range.startIndex)
			}
		}
		return pos
	}
	
	func substringFrom(pos:Int)->String {
		var substr = ""
		let start = self.startIndex.advancedBy(pos)
		let end = self.endIndex
		let range = start..<end
		substr = self[range]
		return substr
	}
	
	func substringTo(pos:Int)->String {
		var substr = ""
		let end = self.startIndex.advancedBy(pos - 1)
		let range = self.startIndex...end
		substr = self[range]
		return substr
	}
}
