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
    let photos: [Photo]?
    var distanceText: String? 

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
struct DistanceMatrixResponse: Codable {
    let destinationAddresses: [String]
    let originAddresses: [String]
    let rows: [Row]
    let status: String

    private enum CodingKeys: String, CodingKey {
        case destinationAddresses = "destination_addresses"
        case originAddresses = "origin_addresses"
        case rows
        case status
    }

    struct Row: Codable {
        let elements: [Element]

        struct Element: Codable {
            let distance: Value?
            let duration: Value?
            let status: String

            struct Value: Codable {
                let text: String
                let value: Int
            }
        }
    }
}
extension Place: Hashable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.place_id == rhs.place_id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(place_id)
    }
}
