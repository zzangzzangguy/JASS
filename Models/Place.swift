import Foundation
import CoreLocation
import GooglePlaces

struct Place: Codable {
    let name: String
    let formatted_address: String?
    let geometry: Geometry
    let place_id: String
    let type: String?
    let phoneNumber: String?
    let openingHours: String?
    var isGym: Bool {
        let gymKeywords = ["헬스", "피트니스", "휘트니스", "운동센터"]
        return gymKeywords.contains(where: name.localizedCaseInsensitiveContains)
    }
    var isPilates: Bool {
        return name.localizedStandardContains("필라테스")
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
