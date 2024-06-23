import Foundation
import CoreLocation

class NearbyFacilitiesViewModel {
    var places: [Place] = [] {
        didSet {
            self.reloadData?()
        }
    }

    var reloadData: (() -> Void)?
    private let placeSearchViewModel = PlaceSearchViewModel()

    func fetchNearbyFacilities(at location: CLLocationCoordinate2D, completion: @escaping () -> Void) {
        print("fetchNearbyFacilities 호출됨: \(location)")
        placeSearchViewModel.searchNearbySportsFacilities(at: location) { [weak self] places in
            self?.places = places.shuffled().prefix(5).map { $0 }
            self?.reloadData?()
            completion()
        }
    }

    func refreshRandomPlaces() {
        self.places.shuffle()
        self.places = Array(self.places.prefix(5))
        reloadData?()
    }
}
