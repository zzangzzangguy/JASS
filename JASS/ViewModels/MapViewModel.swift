import Foundation
import UIKit
import GoogleMaps

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
            print("현재 위치 설정됨: \(currentLocation.coordinate)")
            calculateDistances()
        }
    }

    init(mapView: GMSMapView, placeSearchViewModel: PlaceSearchViewModel, navigationController: UINavigationController?) {
        self.mapView = mapView
        self.placeSearchViewModel = placeSearchViewModel
        self.clusterManager = ClusterManager(mapView: mapView, navigationController: navigationController)
    }

    func calculateDistances() {
        guard let currentLocation = currentLocation else { return }
        let group = DispatchGroup()

        for (index, place) in places.enumerated() {
            group.enter()
            placeSearchViewModel.calculateDistances(from: currentLocation.coordinate, to: place.coordinate) { [weak self] distance in
                defer {
                    group.leave()
                }

                if let distance = distance {
                    self?.places[index].distanceText = distance
                } else {
                    print("거리 계산 실패")
                    self?.places[index].distanceText = "거리 정보 없음"
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.filterPlaces()
            self?.updateMapMarkers()
        }
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
    }

    func updateMapMarkers() {
        mapView.clear()

        for place in filteredPlaces {
            let marker = GMSMarker(position: place.coordinate)
            marker.title = place.name
            let snippet = """
                \(place.formatted_address ?? "주소 정보 없음")
                거리: \(place.distanceText ?? "거리 정보 없음")
            """
            marker.snippet = snippet
            marker.userData = place
            marker.map = mapView
            print("마커 추가: \(place.name), 주소: \(place.formatted_address ?? "정보 없음") 거리: \(place.distanceText ?? "거리 정보 없음")")
        }

        if filteredPlaces.isEmpty {
            print("필터링된 장소가 없습니다. 선택된 카테고리: \(selectedCategories)")
        } else {
            print("필터링된 장소 수: \(filteredPlaces.count)")
            clusterManager.addPlaces(filteredPlaces)
        }
    }

    func updateSelectedPlaceMarker(for place: Place) {
        mapView.clear()  // 기존 마커 제거

        let marker = GMSMarker(position: place.coordinate)
        marker.title = place.name
        let snippet = """
            \(place.formatted_address ?? "주소 정보 없음")
            거리: \(place.distanceText ?? "거리 정보 없음")
        """
        marker.snippet = snippet
        marker.userData = place
        marker.map = mapView

        // 선택한 장소로 맵 이동
        mapView.animate(toLocation: place.coordinate)
        mapView.animate(toZoom: 15) // 적절한 줌 레벨 설정

        print("선택한 장소 마커 추가: \(place.name), 주소: \(place.formatted_address ?? "정보 없음")")
    }
}
