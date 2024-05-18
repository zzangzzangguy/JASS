import GoogleMaps
import GoogleMapsUtils

protocol ClusterManagerDelegate: AnyObject {
    func clusterManager(_ clusterManager: ClusterManager, didSelectPlace place: Place)
    func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, types: [String], completion: @escaping ([Place]) -> Void)
    func selectedFilters() -> Set<String>
    func showNoResultsMessage()
//    func hideNoResultsMessage()
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

    init(mapView: GMSMapView) {
        self.mapView = mapView
        let iconGenerator = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: GMUDefaultClusterIconGenerator())
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        self.clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: iconGenerator)
        super.init()
        self.clusterManager.setDelegate(self, mapDelegate: self)
    }

    func addPlaces(_ places: [Place]) {
        clusterManager.clearItems()
        let items = places.map { CustomClusterItem(place: $0) }
        clusterManager.add(items)
        clusterManager.cluster()
    }

    func updateMarkersWithSelectedFilters() {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)

        let selectedTypes = Array(delegate?.selectedFilters() ?? [])
        delegate?.searchPlacesInBounds(bounds, types: selectedTypes) { [weak self] places in
            guard let self = self else { return }

            self.addPlaces(places)

            if places.isEmpty {
                self.delegate?.showNoResultsMessage()
            } else {
//                self.delegate?.hideNoResultsMessage()
            }
        }
    }
}

extension ClusterManager: GMUClusterManagerDelegate {
    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        if let item = clusterItem as? CustomClusterItem {
            delegate?.clusterManager(self, didSelectPlace: item.place)
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
