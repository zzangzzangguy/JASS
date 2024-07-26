//
//  SearchHistory.swift
//  JASS
//
//  Created by 김기현 on 12/21/23.
//

import RealmSwift
import UIKit

class SearchHistory: Object {
    @objc dynamic var query: String = ""
    @objc dynamic var date: Date = Date()

    convenience init(query: String) {
        self.init()
        self.query = query
        self.date = Date()
    }
}
