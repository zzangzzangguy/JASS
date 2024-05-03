import Foundation
import RealmSwift

class FavoritesManager {
    static let shared = FavoritesManager()
    private var realm: Realm

    private init() {
        realm = try! Realm()  // Realm 초기화
    }

    func addFavorite(placeID: String) {
        let favorite = FavoritePlace()
        favorite.placeID = placeID
        try! realm.write {
            realm.add(favorite)
        }
    }

    func removeFavorite(placeID: String) {
        if let favorite = realm.objects(FavoritePlace.self).filter("placeID == %@", placeID).first {
            try! realm.write {
                realm.delete(favorite)
            }
        }
    }

    func isFavorite(placeID: String) -> Bool {
        return realm.objects(FavoritePlace.self).filter("placeID == %@", placeID).count > 0
    }
}

class FavoritePlace: Object {
    @objc dynamic var placeID: String = ""
}
