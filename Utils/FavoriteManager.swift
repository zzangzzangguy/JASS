import Foundation
import RealmSwift

class FavoritesManager {
    static let shared = FavoritesManager()

    private var realm: Realm?
    private var favorites: Results<FavoritePlace>?

    private init() {
        do {
            realm = try Realm()
            favorites = realm?.objects(FavoritePlace.self)
        } catch {
            print("Realm 초기화 실패: \(error)")
        }
    }

    func addFavorite(place: Place) {
        guard let realm = realm else { return }
        let favorite = FavoritePlace(place: place)
        try! realm.write {
            realm.add(favorite, update: .modified)
            NotificationCenter.default.post(name: .favoritesDidChange, object: place)
        }
    }

    func removeFavorite(place: Place) {
        guard let realm = realm, let favorite = realm.objects(FavoritePlace.self).filter("placeID == %@", place.place_id).first else { return }
        try! realm.write {
            realm.delete(favorite)
            NotificationCenter.default.post(name: .favoritesDidChange, object: place)
        }
    }

    func getFavorites() -> [Place] {
        return favorites?.map { $0.toPlace() } ?? []
    }

    func isFavorite(placeID: String) -> Bool {
        return realm?.objects(FavoritePlace.self).filter("placeID == %@", placeID).count ?? 0 > 0
    }

    func toggleFavorite(place: Place) {
        if isFavorite(placeID: place.place_id) {
            removeFavorite(place: place)
        } else {
            addFavorite(place: place)
        }
    }
}
