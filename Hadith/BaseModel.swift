//
//  BaseModel.swift
//  Hadith
//
//  Created by Majid Khan on 31/05/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation
import SQLite

class BaseModel {
    func buildFromRow(row: Row) -> BaseModel {
        assert(false, "Implement this function in child")
        return BaseModel()
    }
}