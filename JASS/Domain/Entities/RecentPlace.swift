import Foundation
import RealmSwift

class RecentPlace: Object {
    @objc dynamic var place_id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var formatted_address: String? = nil
    @objc dynamic var distanceText: String? = nil
    @objc dynamic var userRatingsTotal: Int = 0
    @objc dynamic var rating: Double = 0.0

    override static func primaryKey() -> String? {
        return "place_id"
    }

    convenience init(place: Place) {
        self.init()
        self.place_id = place.place_id
        self.name = place.name
        self.formatted_address = place.formatted_address
        self.distanceText = place.distanceText
        self.userRatingsTotal = place.userRatingsTotal ?? 0
        self.rating = place.rating ?? 0.0
    }
    
    func toPlace() -> Place {
        return Place(
            name: name,
                   formatted_address: formatted_address,
                   geometry: Place.Geometry(location: Place.Location(lat: 0, lng: 0)),
                   place_id: place_id,
                   types: nil,
                   phoneNumber: nil,
                   openingHours: nil,
                   photos: nil,
                   distanceText: distanceText,
                   reviews: nil,
                   userRatingsTotal: userRatingsTotal,
                   rating: rating
        )
    }
}
