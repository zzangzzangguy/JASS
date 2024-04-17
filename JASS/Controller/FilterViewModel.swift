//
//  FilterViewModel.swift
//  JASS
//
//  Created by 김기현 on 4/17/24.
//

import Foundation
import UIKit

class FilterViewModel {
    let options = ["헬스", "필라테스", "수영", "복싱", "요가", "크로스핏", "격투기", "댄스", "골프", "테니스"]

    var selectedOptions: [String] = [] {
        didSet {
            updateFilters?()
        }
    }

    var updateFilters: (() -> Void)?

    func toggleOption(_ option: String) {
        if let index = selectedOptions.firstIndex(of: option) {
            selectedOptions.remove(at: index)
        } else {
            selectedOptions.append(option)
        }
    }
}
