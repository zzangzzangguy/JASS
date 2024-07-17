import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import GoogleMaps

class PlaceSearchViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let searchText: Observable<String>
        let searchButtonClicked: Observable<Void>
        let keywordSelected: Observable<String>
        let segmentChanged: Observable<Int>
        let currentLocation: Observable<CLLocationCoordinate2D?>
        let loadNextPage: Observable<Void>
        let filterTrigger: Observable<Set<String>>  // 필터 추가
    }

    struct Output {
        let recentSearches: Driver<[String]>
        let autoCompleteSuggestions: Driver<[String]>
        let searchResults: Driver<[Place]>
        let isLoading: Driver<Bool>
        let error: Driver<String>
        let hasNextPage: Driver<Bool>
    }

    private let placeUseCase: PlaceUseCase
    private let searchRecentViewModel: SearchRecentViewModel
    var disposeBag = DisposeBag()

    var searchResults: BehaviorRelay<[Place]> = BehaviorRelay(value: [])
    var isSearching: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var autoCompleteResults: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    var showError: PublishRelay<String> = PublishRelay()
    var cachedPlaces: [String: Place] = [:]

    private var nextPageToken: String?
//    private let pageSize = 10
    public let hasNextPageRelay = BehaviorRelay<Bool>(value: false)


    private let sportKeywords = ["헬스장", "피트니스", "요가", "필라테스", "크로스핏", "수영장", "복싱", "주짓수"]

    init(placeUseCase: PlaceUseCase) {
        self.placeUseCase = placeUseCase
        self.searchRecentViewModel = SearchRecentViewModel.shared
    }

    func transform(input: Input) -> Output {
        let searchTrigger: Observable<Void> = Observable.merge(
            input.searchButtonClicked,
            input.filterTrigger.map { _ in () }
        )

        let searchResults: Observable<[Place]> = searchTrigger
            .withLatestFrom(Observable.combineLatest(input.searchText, input.filterTrigger, input.currentLocation))
            .flatMapLatest { [weak self] (query, filters, location) -> Observable<[Place]> in
                guard let self = self else { return .just([]) }
                return self.searchPlace(input: query, filters: filters, currentLocation: location)
            }
            .share(replay: 1)

        let nextPageResults: Observable<[Place]> = input.loadNextPage
            .flatMapLatest { [weak self] () -> Observable<[Place]> in
                guard let self = self else { return .just([]) }
                return self.loadNextPage()
            }

        let allResults: Observable<[Place]> = Observable.merge(searchResults, nextPageResults)
            .scan(into: [Place]()) { accumulated, new in
                accumulated.append(contentsOf: new)
            }
            .share(replay: 1)

        return Output(
            recentSearches: input.viewDidLoad.flatMapLatest { [weak self] _ in
                Observable.just(self?.searchRecentViewModel.loadRecentSearches() ?? [])
            }.asDriver(onErrorJustReturn: []),
            autoCompleteSuggestions: input.searchText.flatMapLatest { [weak self] query in
                self?.searchAutoComplete(for: query) ?? .just([])
            }.asDriver(onErrorJustReturn: []),
            searchResults: allResults.asDriver(onErrorJustReturn: []),
            isLoading: isSearching.asDriver(),
            error: showError.asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다."),
            hasNextPage: hasNextPageRelay.asDriver()
        )
    }
    func searchPlace(input: String, filters: Set<String>, currentLocation: CLLocationCoordinate2D?) -> Observable<[Place]> {
        isSearching.accept(true)
        nextPageToken = nil
        let category = filters.joined(separator: ",")
        let query = category.isEmpty ? input : "\(input) (\(category))"
        print("DEBUG: 최종 검색 쿼리 - \(query)")


        return placeUseCase.searchPlaces(query: query, pageToken: nil)
            .do(onNext: { [weak self] (places, nextPageToken) in
                self?.isSearching.accept(false)
                
                self?.searchResults.accept((self?.searchResults.value ?? []) + places)
//                self?.searchResults.accept(places)
                self?.nextPageToken = nextPageToken
                self?.hasNextPageRelay.accept(nextPageToken != nil)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
                self?.isSearching.accept(false)
            })
            .map { $0.0 }
    }

    public func loadNextPage() -> Observable<[Place]> {
        guard let token = nextPageToken else {
            print("DEBUG: 다음 페이지 토큰이 없음")
            return .just([])
        }

        isSearching.accept(true)
        print("DEBUG: 다음 페이지 로드 - 토큰: \(token)")

        return placeUseCase.searchPlaces(query: "", pageToken: token)
            .do(onNext: { [weak self] (places, nextPageToken) in
                self?.isSearching.accept(false)
                self?.searchResults.accept((self?.searchResults.value ?? []) + places)
                self?.nextPageToken = nextPageToken
                print("DEBUG: 다음 페이지 로드 완료 - \(places.count)개 결과, 다음 토큰: \(nextPageToken ?? "없음")")
                self?.hasNextPageRelay.accept(nextPageToken != nil)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
                self?.isSearching.accept(false)
            })
            .map { $0.0 }
    }


    func searchAutoComplete(for query: String) -> Observable<[String]> {
        return placeUseCase.getAutocomplete(query: query)
            .map { suggestions in
                suggestions.filter { !$0.contains("대한민국") }
            }
            .do(onNext: { [weak self] suggestions in
                self?.autoCompleteResults.accept(suggestions)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
            })
    }

    func fetchPlaceDetails(placeID: String, completion: @escaping (Place?) -> Void) {
        if let cachedPlace = cachedPlaces[placeID] {
            completion(cachedPlace)
            return
        }

        placeUseCase.getPlaceDetails(placeID: placeID)
            .subscribe(onNext: { [weak self] place in
                self?.cachedPlaces[placeID] = place
                completion(place)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
                completion(nil)
            })
            .disposed(by: disposeBag)
    }

    func fetchPlacePhoto(reference: String, maxWidth: Int) -> Observable<UIImage?> {
        return placeUseCase.getPlacePhotos(reference: reference, maxWidth: maxWidth)
            .map { $0 as UIImage? }
            .do(onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
            })
    }

    func calculateDistances(for places: [Place], from origin: CLLocationCoordinate2D) -> Observable<[Place]> {
        return Observable.from(places)
            .flatMap { place -> Observable<Place> in
                self.placeUseCase.calculateDistances(from: origin, to: place.coordinate)
                    .map { distance -> Place in
                        var updatedPlace = place
                        updatedPlace.distanceText = distance ?? "거리 정보 없음"
                        return updatedPlace
                    }
                    .catchAndReturn(place)
            }
            .toArray()
            .asObservable()
    }

    func searchNearbySportsFacilities(at location: CLLocationCoordinate2D) -> Observable<[Place]> {
        return placeUseCase.searchNearbySportsFacilities(at: location)
            .do(onNext: { [weak self] places in
                self?.searchResults.accept(places)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
            })
    }

    func searchPlacesInBounds(bounds: GMSCoordinateBounds, query: String, completion: @escaping ([Place]) -> Void) {
        placeUseCase.searchPlacesInBounds(bounds: bounds, query: query)
            .subscribe(onNext: { places in
                completion(places)
            }, onError: { error in
                completion([])
            })
            .disposed(by: disposeBag)
    }
}
