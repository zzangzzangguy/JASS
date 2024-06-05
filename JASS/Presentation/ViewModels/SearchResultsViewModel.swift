import Foundation
import UIKit
import Toast

class SearchResultsViewModel {

    private let favoritesManager: FavoritesManager
    private let notificationCenter = NotificationCenter.default
    private weak var viewController: UIViewController?
    

    var searchResults: [Place] = []
    var updateSearchResults: (() -> Void)?

    init(favoritesManager: FavoritesManager, viewController: UIViewController? = nil) {
        self.favoritesManager = favoritesManager
        self.viewController = viewController

        notificationCenter.addObserver(self, selector: #selector(favoritesDidChange(_:)), name: .favoritesDidChange, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc private func favoritesDidChange(_ notification: Notification) {
        guard let place = notification.object as? Place else {
            return
        }

        let isFavorite = favoritesManager.isFavorite(placeID: place.place_id)

        DispatchQueue.main.async {
            if let viewController = self.viewController {
                ToastManager.showToastForFavorite(place: place, isAdded: !isFavorite, in: viewController)
            }
        }
    }

    func updateFavoriteStatus(for place: Place) {
        let isFavorite = favoritesManager.isFavorite(placeID: place.place_id)

        if isFavorite {
            favoritesManager.removeFavorite(place: place)
        } else {
            favoritesManager.addFavorite(place: place)
        }

        updateSearchResults?()
    }

    func loadSearchResults(with places: [Place]) {
        searchResults = places
        updateSearchResults?()
    }
}
