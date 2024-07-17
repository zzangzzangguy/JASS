import Foundation
import RxSwift
import CoreLocation
import GoogleMaps

protocol PlaceRepository {
    func searchPlaces(query: String, pageToken: String?) -> Observable<(places: [Place], nextPageToken: String?)>
    func searchPlacesInBounds(bounds: GMSCoordinateBounds, query: String) -> Observable<[Place]>
    func getPlaceDetails(placeID: String) -> Observable<Place>
    func getPlacePhotos(reference: String, maxWidth: Int) -> Observable<UIImage?>
    func getAutocomplete(query: String) -> Observable<[String]>
    func calculateDistances(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Observable<String?>
    func searchNearbySportsFacilities(at location: CLLocationCoordinate2D) -> Observable<[Place]>
    func getRecentPlaces() -> Observable<[Place]>
    func addRecentPlace(_ place: Place)
}
