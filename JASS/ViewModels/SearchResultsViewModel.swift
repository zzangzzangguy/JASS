import Foundation
import UIKit
import Toast

class SearchResultsViewModel {

    private let favoritesManager: FavoritesManager
    private let notificationCenter = NotificationCenter.default
    private weak var mapViewController: MapViewController?

    var searchResults: [Place] = []
    var updateSearchResults: (() -> Void)?

    init(favoritesManager: FavoritesManager, mapViewController: MapViewController? = nil) {
        self.favoritesManager = favoritesManager
        self.mapViewController = mapViewController

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
            if let mapViewController = self.mapViewController {
                ToastManager.showToastForFavorite(place: place, isAdded: !isFavorite, in: mapViewController)
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
