import RxSwift

protocol RecentPlaceUseCase {
    func getRecentPlaces() -> Observable<[Place]>
    func addRecentPlace(_ place: Place) -> Completable
    func clearRecentPlaces() -> Completable
}

class DefaultRecentPlaceUseCase: RecentPlaceUseCase {
    private let recentPlacesManager: RecentPlacesManager

    init(recentPlacesManager: RecentPlacesManager) {
        self.recentPlacesManager = recentPlacesManager
    }

    func getRecentPlaces() -> Observable<[Place]> {
        return Observable.just(recentPlacesManager.getRecentPlaces())
    }

    func addRecentPlace(_ place: Place) -> Completable {
        return Completable.create { completable in
            self.recentPlacesManager.addRecentPlace(place)
            completable(.completed)
            return Disposables.create()
        }
    }

    func clearRecentPlaces() -> Completable {
        return Completable.create { completable in
            self.recentPlacesManager.clearRecentPlaces()
            completable(.completed)
            return Disposables.create()
        }
    }
}
