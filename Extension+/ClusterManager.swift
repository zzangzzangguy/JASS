import GoogleMaps
import GoogleMapsUtils

protocol ClusterManagerDelegate: AnyObject {
    func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, query: String, completion: @escaping ([Place]) -> Void)
    func selectedFilters() -> Set<String>
    func showNoResultsMessage()
}

class CustomClusterItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    var place: Place

    init(place: Place) {
        self.position = place.coordinate
        self.place = place
    }
}

class ClusterManager: NSObject {
    let mapView: GMSMapView
    let clusterManager: GMUClusterManager
    weak var delegate: ClusterManagerDelegate?
    weak var navigationController: UINavigationController?


    init(mapView: GMSMapView, navigationController: UINavigationController?) {
        self.mapView = mapView
        self.navigationController = navigationController  // UINavigationController의 참조를 저장
        let iconGenerator = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: GMUDefaultClusterIconGenerator())
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        self.clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: iconGenerator)
        super.init()
        self.clusterManager.setDelegate(self, mapDelegate: self)
    }

    func addPlaces(_ places: [Place]) {
        clusterManager.clearItems()
        let items = places.map { CustomClusterItem(place: $0) }
        print("클러스터 아이템 추가: \(items.count)개")

        clusterManager.add(items)
        clusterManager.cluster()
    }

    func updateMarkersWithSelectedFilters() {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        let query = delegate?.selectedFilters().joined(separator: " ") ?? ""

        delegate?.searchPlacesInBounds(bounds, query: query) { [weak self] places in
            guard let self = self else { return }
            self.addPlaces(places)
            if places.isEmpty {
                self.delegate?.showNoResultsMessage()
            }
        }
    }
}

extension ClusterManager: GMUClusterManagerDelegate {
    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        if let item = clusterItem as? CustomClusterItem {
            DispatchQueue.main.async { [weak self] in
                // 안전하게 navigationController 참조를 확인
                guard let self = self, let navigationController = self.navigationController else {
                    print("NavigationController를 찾을 수 없습니다.")
                    return
                }
                let detailVC = GymDetailViewController(place: item.place)
                navigationController.pushViewController(detailVC, animated: true)
            }
            return true
        }
        return false
    }

    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        let newCamera = GMSCameraPosition.camera(withTarget: cluster.position, zoom: mapView.camera.zoom + 1)
        mapView.animate(to: newCamera)
        return true
    }
}

extension ClusterManager: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        updateMarkersWithSelectedFilters()
    }
}
