import Foundation
import RxSwift
import CoreLocation
import GoogleMaps
import UIKit

class DefaultPlaceUseCase: PlaceUseCase {
    private let repository: PlaceRepository

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func searchPlaces(query: String) -> Observable<[Place]> {
        return repository.searchPlaces(query: query)
    }

    func searchPlacesInBounds(bounds: GMSCoordinateBounds, query: String) -> Observable<[Place]> {
        return repository.searchPlacesInBounds(bounds: bounds, query: query)
    }

    func getPlaceDetails(placeID: String) -> Observable<Place> {
        return repository.getPlaceDetails(placeID: placeID)
    }

    func getPlacePhotos(reference: String, maxWidth: Int) -> Observable<UIImage> {
        return repository.getPlacePhotos(reference: reference, maxWidth: maxWidth)
            .compactMap { $0 }
    }

    func getAutocomplete(query: String) -> Observable<[String]> {
        return repository.getAutocomplete(query: query)
    }

    func calculateDistances(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Observable<String?> {
        return repository.calculateDistances(from: origin, to: destination)
    }

    func searchNearbySportsFacilities(at location: CLLocationCoordinate2D) -> Observable<[Place]> {
        return repository.searchNearbySportsFacilities(at: location)
    }
}
