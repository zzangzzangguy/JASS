import Foundation
import RxSwift
import CoreLocation
import GoogleMaps
import UIKit

class DefaultPlaceUseCase: PlaceUseCase {
    private let repository: PlaceRepository
    private let defaultCategory = "헬스장"

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func searchPlaces(query: String, pageToken: String?) -> Observable<([Place], String?)> {
        let finalQuery = query.isEmpty ? defaultCategory : "\(query) \(defaultCategory)"
        print("DEBUG: API 호출 쿼리 - \(finalQuery), 페이지 토큰 - \(pageToken ?? "없음")")

        return repository.searchPlaces(query: finalQuery, pageToken: pageToken)
            .map { response in
                let places = response.places
                let nextPageToken = response.nextPageToken
                print("DEBUG: 검색 결과 - \(places.count)개, 다음 페이지 토큰 - \(String(describing: nextPageToken))")
                return (places, nextPageToken)
            }
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
