import Foundation
import CoreLocation
import RxSwift

class NearbyFacilitiesViewModel {
    var places: [Place] = [] {
        didSet {
            self.reloadData?()
        }
    }

    var reloadData: (() -> Void)?
    private let placeSearchViewModel: PlaceSearchViewModel
    private let disposeBag = DisposeBag()

    init(placeUseCase: PlaceUseCase) {
        self.placeSearchViewModel = PlaceSearchViewModel(placeUseCase: placeUseCase)
    }

    func fetchNearbyFacilities(at location: CLLocationCoordinate2D, completion: @escaping () -> Void) {
        print("fetchNearbyFacilities 호출됨: \(location)")
        placeSearchViewModel.searchNearbySportsFacilities(at: location)
            .subscribe(onNext: { [weak self] places in
                self?.places = Array(places.shuffled().prefix(2))
                self?.reloadData?()
                completion()
            }, onError: { error in
                print("Error: \(error.localizedDescription)")
                completion()
            })
            .disposed(by: disposeBag)
    }

    func refreshRandomPlaces() {
        self.places.shuffle()
        self.places = Array(self.places.prefix(5))
        reloadData?()
    }
}
