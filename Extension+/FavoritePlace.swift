//
//  FavoritePlace.swift
//  
//
//  Created by 김기현 on 5/12/24.
//

import Foundation
import RealmSwift

class FavoritePlace: Object {
    @objc dynamic var placeID: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var formattedAddress: String?
    @objc dynamic var phoneNumber: String?

    convenience init(place: Place) {
        self.init()
        self.placeID = place.place_id
        self.name = place.name
        self.formattedAddress = place.formatted_address
        self.phoneNumber = place.phoneNumber
    }

    func toPlace() -> Place {
        return Place(
            name: name,
            formatted_address: formattedAddress,
            geometry: Place.Geometry(location: Place.Location(lat: 0, lng: 0)),
            place_id: placeID,
            types: nil,
            phoneNumber: phoneNumber,
            openingHours: nil,
            photos: nil
        )
    }
}

extension Notification.Name {
    static let favoritesDidChange = Notification.Name("FavoritesDidChange")
}
