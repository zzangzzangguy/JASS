////
////  Gymload.swift
////  JASS
////
////  Created by 김기현 on 2/13/24.
////
//import Foundation
//import GoogleMaps
//
//class Gymload {
//    private let mapView: GMSMapView
//    private let placeSearchViewModel: PlaceSearchViewModel
//
//    init(mapView: GMSMapView, placeSearchViewModel: PlaceSearchViewModel) {
//        self.mapView = mapView
//        self.placeSearchViewModel = placeSearchViewModel
//    }
//
//    // 지정된 좌표와 반경 내의 체육관을 검색합니다.
//    func searchGymsNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, types: [String], completion: @escaping ([Place]) -> Void) {
//        placeSearchViewModel.searchPlacesNearCoordinate(coordinate, radius: radius, types: types, completion: completion)
//    }
//
//    // 지도가 표시하는 영역 내의 체육관을 로드합니다.
//    func loadGymsInBounds() {
//        let visibleRegion = mapView.projection.visibleRegion()
//        let bounds = GMSCoordinateBounds(region: visibleRegion)
//        placeSearchViewModel.searchPlacesInBounds(bounds, types: ["gym"]) { [weak self] places in
//            self?.handleSearchResults(places)
//        }
//    }
//
//    // 검색 결과를 처리하여 마커를 추가합니다.
//    private func handleSearchResults(_ places: [Place]) {
//        for place in places {
//            addMarker(for: place)
//        }
//    }
//
//    // 주어진 위치에 마커를 추가합니다.
//    private func addMarker(for place: Place) {
//        let marker = GMSMarker()
//        marker.position = CLLocationCoordinate2D(latitude: place.geometry.location.lat, longitude: place.geometry.location.lng)
//        marker.title = place.name
//        marker.snippet = "H."
//        marker.map = mapView
//    }
//}
