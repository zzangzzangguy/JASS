import Foundation
import RxSwift
import RxCocoa
import GoogleMaps
import CoreLocation

class PlaceSearchViewModel {
    private let disposeBag = DisposeBag()
    private let placeUseCase: PlaceUseCase
    private var distanceCache: [String: String] = [:]

    var searchResults: BehaviorRelay<[Place]> = BehaviorRelay(value: [])
    var isSearching: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var autoCompleteResults: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    var showError: PublishRelay<String> = PublishRelay()
    var cachedPlaces: [String: Place] = [:]

    init(placeUseCase: PlaceUseCase) {
        self.placeUseCase = placeUseCase
    }

    func searchPlace(input: String, category: String) -> Observable<[Place]> {
        guard !input.isEmpty else {
            return Observable.just([])
        }

        isSearching.accept(true)
        return placeUseCase.searchPlaces(query: input)
            .do(onNext: { [weak self] places in
                self?.searchResults.accept(places)
                self?.isSearching.accept(false)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
                self?.isSearching.accept(false)
            })
    }

    func fetchPlacePhoto(reference: String, maxWidth: Int) -> Observable<UIImage?> {
        return placeUseCase.getPlacePhotos(reference: reference, maxWidth: maxWidth)
            .map { $0 as UIImage? }
            .do(onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
            })
    }

    func calculateDistances(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let cacheKey = "\(origin.latitude),\(origin.longitude)-\(destination.latitude),\(destination.longitude)"

        if let cachedDistance = distanceCache[cacheKey] {
            completion(cachedDistance)
            return
        }

        placeUseCase.calculateDistances(from: origin, to: destination)
            .subscribe(onNext: { [weak self] distance in
                self?.distanceCache[cacheKey] = distance
                completion(distance)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
                completion(nil)
            })
            .disposed(by: disposeBag)
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

    func searchAutoComplete(for query: String) -> Observable<[String]> {
        return placeUseCase.getAutocomplete(query: query)
            .do(onNext: { [weak self] suggestions in
                self?.autoCompleteResults.accept(suggestions)
            }, onError: { [weak self] error in
                self?.showError.accept(error.localizedDescription)
            })
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
