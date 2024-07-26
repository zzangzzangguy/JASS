import Foundation
import RxSwift
import CoreLocation
import GoogleMaps
import UIKit

protocol PlaceUseCase {
    func searchPlaces(query: String, pageToken: String?) -> Observable<([Place], String?)>
    func searchPlacesInBounds(bounds: GMSCoordinateBounds, query: String) -> Observable<[Place]>
    func getPlaceDetails(placeID: String) -> Observable<Place>
    func getPlacePhotos(reference: String, maxWidth: Int) -> Observable<UIImage>
    func getAutocomplete(query: String) -> Observable<[String]>
    func calculateDistances(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Observable<String?>
    func searchNearbySportsFacilities(at location: CLLocationCoordinate2D) -> Observable<[Place]>
}
