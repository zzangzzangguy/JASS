import Foundation
import UIKit
import GoogleMaps
import CoreLocation

class MapViewModel {
    var mapView: GMSMapView
    var places: [Place] = []
    var filteredPlaces: [Place] = []
    var selectedCategories: Set<String> = []
    var placeSearchViewModel: PlaceSearchViewModel
    var clusterManager: ClusterManager
    var currentLocation: CLLocation? {
        didSet {
            guard let currentLocation = currentLocation else { return }
//            searchGymsNearCurrentLocation(currentLocation)
        }
    }

    init(mapView: GMSMapView, placeSearchViewModel: PlaceSearchViewModel) {
        self.mapView = mapView
        self.placeSearchViewModel = placeSearchViewModel
        self.clusterManager = ClusterManager(mapView: mapView)
    }

    func filterPlaces() {
        if selectedCategories.isEmpty {
            filteredPlaces = places
        } else {
            filteredPlaces = places.filter { place in
                guard let types = place.types, !types.isEmpty else {
                    return false
                }
                return types.contains(where: selectedCategories.contains)
            }
        }
        print("필터링 후 장소 수: \(filteredPlaces.count)")
        updateMapMarkers()
    }


    func updateMapMarkers() {
        mapView.clear()

        for place in filteredPlaces {
            let marker = GMSMarker(position: place.coordinate)
            marker.title = place.name
            marker.snippet = place.formatted_address ?? "주소 정보 없음"
            marker.userData = place // 마커에 Place 객체 할당
            marker.map = mapView
            print("마커 추가: \(place.name), 주소: \(place.formatted_address ?? "정보 없음")")
        }

        if filteredPlaces.isEmpty {
            print("필터링된 장소가 없습니다. 선택된 카테고리: \(selectedCategories)")
        } else {
            print("필터링된 장소 수: \(filteredPlaces.count)")
            clusterManager.addPlaces(filteredPlaces)
        }
    }
}
