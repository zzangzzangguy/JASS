import Foundation
import RxSwift
import GoogleMaps

class PlaceRepositoryImpl: PlaceRepository {
    private let apiService: GooglePlacesAPIService
    private var recentPlaces: [Place] = [] 

    init(apiService: GooglePlacesAPIService) {
        self.apiService = apiService
    }

    func searchPlaces(query: String) -> Observable<[Place]> {
        return apiService.searchPlaces(query: query)
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

    func getRecentPlaces() -> Observable<[Place]> { // 추가
        return Observable.just(recentPlaces)
    }

    func addRecentPlace(_ place: Place) { // 추가
        if !recentPlaces.contains(where: { $0.place_id == place.place_id }) {
            recentPlaces.append(place)
            if recentPlaces.count > 10 {
                recentPlaces.removeFirst()
            }
        }
    }
}
