import GoogleMaps
import GoogleMapsUtils
import UIKit
import RxSwift
import RxCocoa

class MapViewModel {
    var mapView: GMSMapView
    var places: BehaviorRelay<[Place]> = BehaviorRelay(value: [])
    var filteredPlaces: [Place] = []
    var selectedCategories: Set<String> = []
    var placeSearchViewModel: PlaceSearchViewModel
    var clusterManager: ClusterManager
    var coordinator: MapCoordinator?
    var currentLocation: CLLocation? {
        didSet {
            guard let currentLocation = currentLocation else {
                print("맵뷰 모델 현재 위치를 가져올 수 없습니다.")
                return
            }
            print("현재 위치 설정됨: \(currentLocation.coordinate)")
        }
    }

    var isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var errorMessage: BehaviorRelay<String?> = BehaviorRelay(value: nil)

    init(
        mapView: GMSMapView,
        placeSearchViewModel: PlaceSearchViewModel,
        navigationController: UINavigationController?,
        coordinator: MapCoordinator?
    ) {
        self.mapView = mapView
        self.placeSearchViewModel = placeSearchViewModel
        self.clusterManager = ClusterManager(mapView: mapView, navigationController: navigationController, coordinator: coordinator)
        self.coordinator = coordinator
    }


//    func calculateDistances() {
//        guard let currentLocation = currentLocation else { return }
//        let group = DispatchGroup()
//        var updatedPlaces = places.value
//
//        for (index, place) in places.value.enumerated() {
//            group.enter()
//            placeSearchViewModel.calculateDistances(from: currentLocation.coordinate, to: place.coordinate) { [weak self] distance in
//                defer { group.leave() }
//                if let distance = distance {
//                    updatedPlaces[index].distanceText = distance
//                } else {
//                    print("거리 계산 실패")
//                    updatedPlaces[index].distanceText = "거리 정보 없음"
//                }
//            }
//        }
//
//        group.notify(queue: .main) { [weak self] in
//            self?.places.accept(updatedPlaces)
//            self?.filterPlaces()
//            self?.updateMapMarkers()
//        }
//    }


    func filterPlaces() {
        if selectedCategories.isEmpty {
            filteredPlaces = places.value
        } else {
            filteredPlaces = places.value.filter { place in
                guard let types = place.types else { return false }
                return !Set(types).isDisjoint(with: selectedCategories)
            }
        }
        print("필터링 후 장소 수: \(filteredPlaces.count)")
    }

    func updateMapMarkers() {
        mapView.clear()

        for place in filteredPlaces {
            clusterManager.addCustomMarker(at: place.coordinate, title: place.name, snippet: """
                \(place.formatted_address ?? "주소 정보 없음")
                거리: \(place.distanceText ?? "거리 정보 없음")
            """)
        }

        if filteredPlaces.isEmpty {
            print("필터링된 장소가 없습니다. 선택된 카테고리: \(selectedCategories)")
        } else {
            print("필터링된 장소 수: \(filteredPlaces.count)")
            clusterManager.addPlaces(filteredPlaces)
        }
    }

    func updateSelectedPlaceMarker(for place: Place) {
        filteredPlaces.removeAll()
        mapView.clear()

        let marker = clusterManager.addCustomMarker(at: place.coordinate, title: place.name, snippet: """
            \(place.formatted_address ?? "주소 정보 없음")
            거리: \(place.distanceText ?? "거리 정보 없음")
        """)
        marker.userData = place

        mapView.animate(toLocation: place.coordinate)
        mapView.animate(toZoom: 15)

        print("선택한 장소 마커 추가: \(place.name), 주소: \(place.formatted_address ?? "정보 없음")")
    }

    func updateMarkersWithSearchResults(_ places: [Place]) {
        filteredPlaces.removeAll()
        mapView.clear()
        clusterManager.addPlaces(filteredPlaces)

        for place in places {
            clusterManager.addCustomMarker(at: place.coordinate, title: place.name, snippet: """
                \(place.formatted_address ?? "주소 정보 없음")
                거리: \(place.distanceText ?? "거리 정보 없음")
            """)
        }

        clusterManager.addPlaces(places)
    }
}
