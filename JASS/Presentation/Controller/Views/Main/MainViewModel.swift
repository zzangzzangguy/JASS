
import Foundation
import RxSwift
import RxCocoa
import CoreLocation

class MainViewModel {
    private let disposeBag = DisposeBag()
    private let placeSearchViewModel: PlaceSearchViewModel
    private let nearbyFacilitiesUseCase: NearbyFacilitiesUseCase

    var isLoading = BehaviorRelay<Bool>(value: false)
    var error = PublishRelay<String>()
    var places = BehaviorRelay<[Place]>(value: [])

    init(placeSearchViewModel: PlaceSearchViewModel, nearbyFacilitiesUseCase: NearbyFacilitiesUseCase) {
        self.placeSearchViewModel = placeSearchViewModel
        self.nearbyFacilitiesUseCase = nearbyFacilitiesUseCase
    }

    func fetchNearbyFacilities(at location: CLLocationCoordinate2D) {
        isLoading.accept(true)
        nearbyFacilitiesUseCase.fetchNearbyFacilities(at: location)
            .subscribe(onNext: { [weak self] places in
                self?.places.accept(places)
                self?.isLoading.accept(false)
            }, onError: { [weak self] error in
                self?.error.accept(error.localizedDescription)
                self?.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }

    func fetchPlaceDetails(placeID: String, completion: @escaping (Place?) -> Void) {
        placeSearchViewModel.fetchPlaceDetails(placeID: placeID) { place in
            completion(place)
        }
    }
}
