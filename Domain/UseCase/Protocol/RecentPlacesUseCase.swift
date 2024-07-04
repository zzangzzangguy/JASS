import Foundation
import RxSwift

protocol RecentPlacesUseCase {
    var recentPlaces: Observable<[Place]> { get }
    func addRecentPlace(_ place: Place)
}

class DefaultRecentPlacesUseCase: RecentPlacesUseCase {
    private let repository: PlaceRepository

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    var recentPlaces: Observable<[Place]> {
        return repository.getRecentPlaces()
    }

    func addRecentPlace(_ place: Place) {
        repository.addRecentPlace(place)
    }
}
