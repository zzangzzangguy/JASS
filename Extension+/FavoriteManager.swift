import Foundation
import RealmSwift

class FavoritesManager {
    static let shared = FavoritesManager()

    private let realm = try! Realm()
    private let favorites: Results<FavoritePlace>

    private init() {
        favorites = realm.objects(FavoritePlace.self)
    }

    func addFavorite(place: Place) {
        let favorite = FavoritePlace(place: place)
        try! realm.write {
            realm.add(favorite)
            NotificationCenter.default.post(name: .favoritesDidChange, object: self)
        }
    }

    func removeFavorite(place: Place) {
        guard let favorite = realm.objects(FavoritePlace.self).filter("placeID == %@", place.place_id).first else { return }
        try! realm.write {
            realm.delete(favorite)
            NotificationCenter.default.post(name: .favoritesDidChange, object: self)
        }
    }

    func getFavorites() -> [Place] {
        return favorites.map { $0.toPlace() }
    }

    func isFavorite(placeID: String) -> Bool {
        return realm.objects(FavoritePlace.self).filter("placeID == %@", placeID).count > 0
    }
}


//class FavoritePlace: Object {
//    @objc dynamic var placeID: String = ""
//    @objc dynamic var name: String = ""
//    @objc dynamic var formattedAddress: String?
//    @objc dynamic var phoneNumber: String?
//
//    convenience init(place: Place) {
//        self.init()
//        self.placeID = place.place_id
//        self.name = place.name
//        self.formattedAddress = place.formatted_address
//        self.phoneNumber = place.phoneNumber
//    }
//
//    func toPlace() -> Place {
//        return Place(
//            name: name,
//            formatted_address: formattedAddress,
//            geometry: Place.Geometry(location: Place.Location(lat: 0, lng: 0)),
//            place_id: placeID,
//            types: nil,
//            phoneNumber: phoneNumber,
//            openingHours: nil,
//            photos: nil
//        )
//    }
//}
//
//extension Notification.Name {
//    static let favoritesDidChange = Notification.Name("FavoritesDidChange")
//}
