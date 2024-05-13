import GoogleMaps
import GoogleMapsUtils

protocol ClusterManagerDelegate: AnyObject {
    func clusterManager(_ clusterManager: ClusterManager, didSelectPlace place: Place)
}

struct ClusterPlace {
    var coordinate: CLLocationCoordinate2D
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
        self.clusterManager.setDelegate(self, mapDelegate: nil)
    }

    func addPlaces(_ places: [Place]) {
        clusterManager.clearItems()
        let items = places.map { CustomClusterItem(place: $0) }
        for item in items {
            clusterManager.add(item)
        }
        clusterManager.cluster()
        print("클러스터 아이템 추가 완료")
    }
}

extension ClusterManager: GMUClusterManagerDelegate {
    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        if let item = clusterItem as? CustomClusterItem {
            let place = item.place
            delegate?.clusterManager(self, didSelectPlace: place)
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
