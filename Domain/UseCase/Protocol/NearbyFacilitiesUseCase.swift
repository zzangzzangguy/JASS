import Foundation
import RxSwift
import CoreLocation

protocol NearbyFacilitiesUseCase {
    func fetchNearbyFacilities(at location: CLLocationCoordinate2D) -> Observable<[Place]>
}

class DefaultNearbyFacilitiesUseCase: NearbyFacilitiesUseCase {
    private let repository: PlaceRepository

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func fetchNearbyFacilities(at location: CLLocationCoordinate2D) -> Observable<[Place]> {
        return repository.searchNearbySportsFacilities(at: location)
    }
}
