import Foundation
import UIKit
import Toast

class SearchResultsViewModel {

    private let favoritesManager: FavoritesManager
    private let notificationCenter = NotificationCenter.default
    private weak var viewController: UIViewController?
    var searchResults: [Place] = [] {
           didSet {
//               print("DEBUG: 검색 결과 업데이트 - 총 \(searchResults.count)개 장소")
               searchResults.forEach { place in
//                   print("DEBUG: 업데이트된 장소 - 이름: \(place.name), 거리: \(place.distanceText ?? "없음")")
               }
           }
       }
    var updateSearchResults: (() -> Void)?

    init(favoritesManager: FavoritesManager, viewController: UIViewController? = nil) {
        self.favoritesManager = favoritesManager
//        self.viewController = viewController

        notificationCenter.addObserver(self, selector: #selector(favoritesDidChange(_:)), name: .favoritesDidChange, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc private func favoritesDidChange(_ notification: Notification) {
        guard let place = notification.object as? Place else {
            return
        }

        let isFavorite = favoritesManager.isFavorite(placeID: place.place_id ?? "")

        DispatchQueue.main.async {
            if let viewController = self.viewController {
                let message = isFavorite ? "즐겨찾기에서 제거되었습니다." : "즐겨찾기에 추가되었습니다."
                viewController.view.makeToast(message)
            }
        }
    }

    func updateFavoriteStatus(for place: Place) {
        let wasFavorite = favoritesManager.isFavorite(placeID: place.place_id ?? "")

        if wasFavorite {
            favoritesManager.removeFavorite(place: place)
        } else {
            favoritesManager.addFavorite(place: place)
        }

        let message = wasFavorite ? "즐겨찾기에서 제거되었습니다." : "즐겨찾기에 추가되었습니다."
        viewController?.view.makeToast(message)
    }



    func updatePlace(_ updatedPlace: Place) {
        if let index = searchResults.firstIndex(where: { $0.place_id == updatedPlace.place_id }) {
            searchResults[index] = updatedPlace
            updateSearchResults?()
        }
        func setViewController(_ viewController: UIViewController) {
               self.viewController = viewController
           }

    }



    func loadSearchResults(with places: [Place]) {
        print("DEBUG: 검색 결과 업데이트 - 총 \(places.count)개 장소")
        self.searchResults = places
        places.forEach { place in
            print("DEBUG: 업데이트된 장소 - 이름: \(place.name), 거리: \(place.distanceText ?? "없음")")
        }
        updateSearchResults?()
    }
}
