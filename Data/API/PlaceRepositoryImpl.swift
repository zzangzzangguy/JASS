import Foundation
import RxSwift
import RxCocoa
import GoogleMaps

class PlaceRepositoryImpl: PlaceRepository {
    private let apiService: GooglePlacesAPIService
    private var recentPlaces: [Place] = []

    init(apiService: GooglePlacesAPIService) {
        self.apiService = apiService
    }

    func searchPlaces(query: String, pageToken: String?) -> Observable<(places: [Place], nextPageToken: String?)> {
        return apiService.searchPlaces(query: query, pageToken: pageToken)
            .map { results in
                print("DEBUG: Repository 검색 결과 - \(results.0.count)개, 다음 페이지 토큰 - \(String(describing: results.1))")
                return (places: results.0, nextPageToken: results.1)
            }
    }
    func searchPlacesInBounds(bounds: GMSCoordinateBounds, query: String) -> Observable<[Place]> {
        let center = CLLocationCoordinate2D(latitude: (bounds.northEast.latitude + bounds.southWest.latitude) / 2,
                                            longitude: (bounds.northEast.longitude + bounds.southWest.longitude) / 2)
        let radius = min(bounds.northEast.distance(to: bounds.southWest) / 2, 5000)
        let parameters: [String: Any] = [
            "location": "\(center.latitude),\(center.longitude)",
            "radius": Int(radius),
            "keyword": query,
            "type": ""
        ]
        return apiService.searchPlacesInBounds(parameters: parameters)
    }

    func getPlaceDetails(placeID: String) -> Observable<Place> {
        return apiService.getPlaceDetails(placeID: placeID)
    }

    func getPlacePhotos(reference: String, maxWidth: Int) -> Observable<UIImage?> {
        return apiService.getPlacePhotos(reference: reference, maxWidth: maxWidth)
    }

    func getAutocomplete(query: String) -> Observable<[String]> {
        return apiService.getAutocomplete(query: query)
    }

    func calculateDistances(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Observable<String?> {
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        return apiService.calculateDistances(origins: originString, destinations: destinationString)
            .do(onNext: { distances in
            }, onError: { error in
                print("DEBUG: 거리 계산 오류: \(error.localizedDescription)")
            })
            .map { distances -> String? in
                return distances.first ?? nil
            }
    }

    func searchNearbySportsFacilities(at location: CLLocationCoordinate2D) -> Observable<[Place]> {
        let radius = 5000
        let parameters: [String: Any] = [
            "location": "\(location.latitude),\(location.longitude)",
            "radius": radius,
            "type": "gym"
        ]
        return apiService.searchNearby(parameters: parameters)
    }

    func getRecentPlaces() -> Observable<[Place]> {
        return Observable.just(recentPlaces)
    }

    func addRecentPlace(_ place: Place) {
        if !recentPlaces.contains(where: { $0.place_id == place.place_id }) {
            recentPlaces.append(place)
            if recentPlaces.count > 10 {
                recentPlaces.removeFirst()
            }
        }
    }
}
