import Foundation
import RxCocoa
import RxSwift

final class SearchResultsViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let searchTrigger: Observable<String>
        let filterTrigger: Observable<Set<String>>
        let itemSelected: Observable<Int>
        let favoriteToggle: Observable<Place>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let searchResults: Driver<[Place]>
        let error: Driver<String>
        let favoriteUpdated: Driver<Place>
    }

    let favoritesManager: FavoritesManager
    private let placeSearchViewModel: PlaceSearchViewModel
    private let recentPlacesViewModel: RecentPlacesViewModel
    var disposeBag = DisposeBag()

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<String>()
    private let favoriteUpdatedRelay = PublishRelay<Place>()
    let searchResultsRelay = BehaviorRelay<[Place]>(value: [])
    let favoriteStatusChanged = PublishRelay<String>()


    init(favoritesManager: FavoritesManager, placeSearchViewModel: PlaceSearchViewModel, recentPlacesViewModel: RecentPlacesViewModel) {
        self.favoritesManager = favoritesManager
        self.placeSearchViewModel = placeSearchViewModel
        self.recentPlacesViewModel = recentPlacesViewModel
    }

    func transform(input: Input) -> Output {
        input.searchTrigger
            .do(onNext: { [weak self] _ in self?.isLoadingRelay.accept(true) })
            .flatMapLatest { [weak self] query -> Observable<[Place]> in
                guard let self = self else { return Observable.just([]) }
                return self.placeSearchViewModel.searchPlace(input: query, category: "", currentLocation: nil)
                    .catch { error in
                        self.errorRelay.accept(error.localizedDescription)
                        return Observable.just([])
                    }
            }
            .do(onNext: { [weak self] places in
                self?.isLoadingRelay.accept(false)
                self?.searchResultsRelay.accept(places)
            })
            .subscribe()
            .disposed(by: disposeBag)

        input.favoriteToggle
            .subscribe(onNext: { [weak self] place in
                self?.updateFavoriteStatus(for: place)
                self?.favoriteUpdatedRelay.accept(place)
                self?.favoriteStatusChanged.accept(place.place_id)
            })
            .disposed(by: disposeBag)

        input.itemSelected
            .withLatestFrom(searchResultsRelay) { ($0, $1) }
            .subscribe(onNext: { [weak self] index, places in
                guard index < places.count else { return }
                let place = places[index]
                self?.recentPlacesViewModel.addRecentPlace(place)
            })
            .disposed(by: disposeBag)

        return Output(
            isLoading: isLoadingRelay.asDriver(),
            searchResults: searchResultsRelay.asDriver(),
            error: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다."),
            favoriteUpdated: favoriteUpdatedRelay.asDriver(onErrorJustReturn: Place(
                name: "",
                formatted_address: nil,
                geometry: Place.Geometry(location: Place.Location(lat: 0, lng: 0)),
                place_id: "",
                types: nil,
                phoneNumber: nil,
                openingHours: nil,
                photos: nil,
                distanceText: nil,
                reviews: nil
            ))
        )
    }

    func updateFavoriteStatus(for place: Place) {
        let wasFavorite = favoritesManager.isFavorite(placeID: place.place_id)
        favoritesManager.toggleFavorite(place: place)

        if let index = searchResultsRelay.value.firstIndex(where: { $0.place_id == place.place_id }) {
            var updatedPlaces = searchResultsRelay.value
            updatedPlaces[index] = place
            searchResultsRelay.accept(updatedPlaces)
        }
        favoriteStatusChanged.accept(place.place_id)
    }

    func loadSearchResults(with places: [Place]) {
        self.searchResultsRelay.accept(places)
    }

    func getRecentPlaces() -> [Place] {
        return recentPlacesViewModel.loadRecentPlaces()
    }
}
