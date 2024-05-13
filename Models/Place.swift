import Foundation
import GooglePlaces

struct Place: Codable {
    let name: String
    let formatted_address: String?
    let geometry: Geometry
    let place_id: String
    let types: [String]?
    let phoneNumber: String?
    let openingHours: String?
    let photos: [Photo]?  // 수정: imageURL 프로퍼티 제거, photos 프로퍼티 추가

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
}

struct Photo: Codable {  // 추가: Photo 구조체 추가
    let height: Int
    let width: Int
    let photoReference: String

    enum CodingKeys: String, CodingKey {
        case height
        case width
        case photoReference = "photo_reference"
    }
}
