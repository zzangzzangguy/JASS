import Foundation
import RxSwift
import RxCocoa

class RecentPlacesViewModel {
    private let recentPlaceUseCase: RecentPlaceUseCase
    private let disposeBag = DisposeBag()
    private let maxRecentPlaces = 5

    let recentPlacesRelay = BehaviorRelay<[Place]>(value: [])

    init(recentPlaceUseCase: RecentPlaceUseCase) {
        self.recentPlaceUseCase = recentPlaceUseCase
        loadRecentPlaces()
    }

    func loadRecentPlaces() {
        recentPlaceUseCase.getRecentPlaces()
            .map { Array($0.prefix(self.maxRecentPlaces)) }
            .subscribe(onNext: { [weak self] places in
                self?.recentPlacesRelay.accept(places)
            })
            .disposed(by: disposeBag)
    }

    func addRecentPlace(_ place: Place) {
        var currentPlaces = recentPlacesRelay.value
        if let index = currentPlaces.firstIndex(where: { $0.place_id == place.place_id }) {
            currentPlaces.remove(at: index)
        }
        currentPlaces.insert(place, at: 0)
        currentPlaces = Array(currentPlaces.prefix(maxRecentPlaces))

        recentPlaceUseCase.addRecentPlace(place)
            .subscribe(onCompleted: { [weak self] in
                self?.recentPlacesRelay.accept(currentPlaces)
            })
            .disposed(by: disposeBag)
    }

    var recentPlaces: Observable<[Place]> {
        return recentPlacesRelay.asObservable()
    }

    func getRecentPlaces() -> [Place] {
        return recentPlacesRelay.value
    }
}
