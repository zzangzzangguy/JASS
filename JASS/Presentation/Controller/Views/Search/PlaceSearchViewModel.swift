import Foundation
import RxSwift
import RxCocoa
import GoogleMaps
import CoreLocation

class PlaceSearchViewModel {
    private let disposeBag = DisposeBag()
    private let placeUseCase: PlaceUseCase
//    private var distanceCache: [String: String] = [:]

    var searchResults: BehaviorRelay<[Place]> = BehaviorRelay(value: [])
    var isSearching: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var autoCompleteResults: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    var showError: PublishRelay<String> = PublishRelay()
    var cachedPlaces: [String: Place] = [:]

    init(placeUseCase: PlaceUseCase) {
        self.placeUseCase = placeUseCase
    }

    func searchPlace(input: String, category: String, currentLocation: CLLocationCoordinate2D?) -> Observable<[Place]> {
        return placeUseCase.searchPlaces(query: input + "헬스,필라테스,수영장,요가,크로스핏,복싱,G.X,주짓수,골프,수영")
            .map { places in
                return places.filter { $0.isGym }
            }
//            .flatMap { [weak self] places -> Observable<[Place]> in
//                guard let self = self, let location = currentLocation else {
//                    return Observable.just(places)
//                }
//                return self.calculateDistances(for: places, from: location)
//            }
            .do(onNext: { [weak self] places in
//                self?.searchResults.accept(places)
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

    func calculateDistances(for places: [Place], from origin: CLLocationCoordinate2D) -> Observable<[Place]> {
        print("DEBUG: 거리 계산 시작 - 장소 수: \(places.count)")
        return Observable.from(places)
            .flatMap { place -> Observable<Place> in
                return self.placeUseCase.calculateDistances(from: origin, to: place.coordinate)
                    .map { distance -> Place in
                        var updatedPlace = place
                        updatedPlace.distanceText = distance ?? "거리 정보 없음"
                        print("DEBUG: 거리 계산 결과 - 장소: \(place.name), 거리: \(updatedPlace.distanceText)")
                        return updatedPlace
                    }
                    .catchAndReturn(place)
            }
            .toArray()
            .asObservable()
            .do(onNext: { places in
                print("DEBUG: 모든 거리 계산 완료 - 총 \(places.count)개 장소")
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

    func searchAutoComplete(for query: String) -> Observable<[String]> {
        return placeUseCase.getAutocomplete(query: query)
            .map { suggestions in
                return suggestions.filter { !$0.contains("대한민국") }
            }
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
