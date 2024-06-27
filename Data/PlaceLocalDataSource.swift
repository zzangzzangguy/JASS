//import Foundation
//import RealmSwift
//
//protocol PlaceLocalDataSource {
//    func savePlaces(_ places: [Place])
//    func getPlaces() -> [Place]
//}
//
//class RealmPlaceLocalDataSource: PlaceLocalDataSource {
//    private let realm: Realm
//
//    init() {
//        realm = try! Realm()
//    }
//
//    func savePlaces(_ places: [Place]) {
//        try! realm.write {
//            realm.add(places.map { RealmPlace(place: $0) }, update: .modified)
//        }
//    }
//
//    func getPlaces() -> [Place] {
//        return realm.objects(RealmPlace.self).map { $0.toPlace() }
//    }
//}
//
//class RealmPlace: Object {
//    @objc dynamic var placeID = ""
//    @objc dynamic var name = ""
//    @objc dynamic var formattedAddress: String?
//
//    override static func primaryKey() -> String? {
//        return "placeID"
//    }
//
//    convenience init(place: Place) {
//        self.init()
//        self.placeID = place.placeID
//        self.name = place.name
//        self.formattedAddress = place.formattedAddress
//    }
//
//    func toPlace() -> Place {
//        return Place(name: name, formattedAddress: formattedAddress, geometry: Place.Geometry(location: Place.Location(lat: 0, lng: 0)), placeID: placeID, types: nil, phoneNumber: nil, openingHours: nil, photos: nil)
//    }
//}
