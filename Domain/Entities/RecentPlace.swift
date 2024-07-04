import Foundation
import RealmSwift

class RecentPlace: Object {
    @objc dynamic var place_id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var formatted_address: String? = nil
    @objc dynamic var distanceText: String? = nil

    override static func primaryKey() -> String? {
        return "place_id"
    }

    convenience init(place: Place) {
        self.init()
        self.place_id = place.place_id
        self.name = place.name
        self.formatted_address = place.formatted_address
        self.distanceText = place.distanceText
    }

    func toPlace() -> Place {
        return Place(
            name: name,
            formatted_address: formatted_address,
            geometry: Place.Geometry(location: Place.Location(lat: 0, lng: 0)), // 적절한 기본값 제공
            place_id: place_id,
            types: nil,
            phoneNumber: nil,
            openingHours: nil,
            photos: nil,
            distanceText: distanceText,
            reviews: nil
        )
    }
}
