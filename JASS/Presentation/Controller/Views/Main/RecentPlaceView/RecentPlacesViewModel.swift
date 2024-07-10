import Foundation
import RxSwift
import RxCocoa

class RecentPlacesViewModel {
    let recentPlacesRelay = BehaviorRelay<[Place]>(value: [])
    private let maxRecentPlaces = 5
    private let recentPlacesManager: RecentPlacesManager

    init(recentPlacesManager: RecentPlacesManager) {
        self.recentPlacesManager = recentPlacesManager
        self.recentPlacesRelay.accept(recentPlacesManager.getRecentPlaces())
    }

    var recentPlaces: Observable<[Place]> {
        return recentPlacesRelay.asObservable().distinctUntilChanged()
    }

    func addRecentPlace(_ place: Place) {
        var currentPlaces = recentPlacesRelay.value
        if let index = currentPlaces.firstIndex(where: { $0.place_id == place.place_id }) {
            currentPlaces.remove(at: index)
        }
        currentPlaces.insert(place, at: 0)
        if currentPlaces.count > maxRecentPlaces {
            currentPlaces.removeLast()
        }
        recentPlacesRelay.accept(currentPlaces)
        recentPlacesManager.addRecentPlace(place)
    }

    func loadRecentPlaces() -> [Place] {
        return recentPlacesRelay.value
    }
}
