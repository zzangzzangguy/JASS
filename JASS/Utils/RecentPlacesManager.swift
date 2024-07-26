import RealmSwift
import Foundation

class RecentPlacesManager {
    private let realm = try! Realm()

    func addRecentPlace(_ place: Place) {
        let recentPlace = RecentPlace(place: place)
        try! realm.write {
            realm.add(recentPlace, update: .modified)
        }
    }

    func getRecentPlaces() -> [Place] {
        let recentPlaces = realm.objects(RecentPlace.self).sorted(byKeyPath: "name", ascending: true) // 정렬 기준을 필요에 따라 조정
        return recentPlaces.map { $0.toPlace() }
    }

    func clearRecentPlaces() {
        let recentPlaces = realm.objects(RecentPlace.self)
        try! realm.write {
            realm.delete(recentPlaces)
        }
    }
}
