import Foundation
import CoreLocation
import GooglePlaces

struct Place: Codable {
    let name: String
    let formatted_address: String?
    let geometry: Geometry
    let place_id: String
    let types: [String]?
    let phoneNumber: String?
    let openingHours: String?

    var isGym: Bool {
        guard let types = types else { return false }
        return types.contains("gym") || types.contains("health")
    }

    var isPilates: Bool {
        guard let types = types else { return false }
        return types.contains("pilates")
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: geometry.location.lat, longitude: geometry.location.lng)
    }

    struct Geometry: Codable {
        let location: Location
    }

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }

    struct SearchResults: Codable {
        let results: [Place]
    }
}
