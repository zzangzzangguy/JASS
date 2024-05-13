//
//  ToastManager.swift
//  JASS
//
//  Created by 김기현 on 5/13/24.
//

import UIKit
import Toast

struct ToastManager {
    static func showToast(message: String, in viewController: UIViewController) {
        viewController.view.makeToast(message)
    }

    static func showToastForFavorite(place: Place, isAdded: Bool, in viewController: UIViewController) {
        let message = isAdded ? "즐겨찾기에 추가되었습니다." : "즐겨찾기에서 제거되었습니다."
        showToast(message: message, in: viewController)
    }
}
