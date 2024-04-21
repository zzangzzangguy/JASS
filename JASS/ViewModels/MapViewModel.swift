import Foundation
import UIKit
import GoogleMaps
import GooglePlaces

class MapViewModel {
    var mapView: GMSMapView!
    var markers: [GMSMarker] = []
    var places: [Place] = []
    var selectedCategories: Set<String> = []
    var filteredPlaces: [Place] = [] {
        didSet {
            updateMarkers?()
        }
    }
    var updateMarkers: (() -> Void)?
    var gymLoader: Gymload!
    var currentLocation: CLLocation?

    init(mapView: GMSMapView, placeSearchViewModel: PlaceSearchViewModel) {
        self.mapView = mapView
        self.gymLoader = Gymload(mapView: mapView, placeSearchViewModel: placeSearchViewModel)
    }

    func loadGymsInBounds() {
        gymLoader.loadGymsInBounds()
    }

    func searchGymsNearCurrentLocation() {
        guard let currentLocation = currentLocation else {
            print("현재 위치를 가져올 수 없습니다.")
            return
        }

        let coordinate = currentLocation.coordinate
        let radius = 5000.0 // 5km 반경

        gymLoader.searchGymsNearCoordinate(coordinate, radius: radius) { [weak self] places in
            self?.places = places
            self?.filteredPlaces = places
        }
    }

    func filterPlaces(with options: [String]) {
        filteredPlaces = places.filter { place in
            guard let type = place.type else { return false }
            return options.contains(type)
        }
    }

    func updateMapView() {
        mapView.clear()

        for place in filteredPlaces {
            let marker = GMSMarker(position: place.coordinate)
            marker.title = place.name
            marker.map = mapView
            markers.append(marker)
        }

        if let firstPlace = filteredPlaces.first {
            let camera = GMSCameraPosition.camera(withTarget: firstPlace.coordinate, zoom: 15)
            mapView.animate(to: camera)
        }
    }

    func didTapMarker(_ marker: GMSMarker) -> Place? {
        guard let index = markers.firstIndex(of: marker) else { return nil }
        return filteredPlaces[index]
    }
}
