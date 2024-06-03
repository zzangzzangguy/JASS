import GoogleMaps
import GoogleMapsUtils
import UIKit

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

class ClusterManager: NSObject, GMUClusterManagerDelegate, GMUClusterRendererDelegate, GMSMapViewDelegate {
    let mapView: GMSMapView
    let clusterManager: GMUClusterManager
    weak var delegate: ClusterManagerDelegate?
    weak var navigationController: UINavigationController?

    init(mapView: GMSMapView, navigationController: UINavigationController?) {
        self.mapView = mapView
        self.navigationController = navigationController
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        self.clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        super.init()
        self.clusterManager.setDelegate(self, mapDelegate: self)
        renderer.delegate = self // 클러스터 렌더러의 delegate를 설정
    }

    func addPlaces(_ places: [Place]) {
        clusterManager.clearItems()
        let items = places.map { CustomClusterItem(place: $0) }
        clusterManager.add(items)
        clusterManager.cluster()
    }

    func addCustomMarker(at location: CLLocationCoordinate2D, title: String? = nil, snippet: String? = nil) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = location
        marker.title = title
        marker.snippet = snippet

        // 사용자 정의 마커 아이콘 설정
        if let title = title, let markerIcon = createMarkerIcon(with: title) {
            marker.icon = markerIcon
        }

        marker.map = mapView // 수정된 부분
        return marker
    }

    func updateMarkersWithSelectedFilters() {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        let selectedCategories = delegate?.selectedFilters() ?? []

        guard !selectedCategories.isEmpty else {
            mapView.makeToast("선택된 필터가 없습니다. 필터른 선택해주세ㅇ.")
            return
        }

        var allPlaces: [Place] = []
        let group = DispatchGroup()

        for category in selectedCategories {
            group.enter()
            delegate?.searchPlacesInBounds(bounds, query: category) { places in
                allPlaces.append(contentsOf: places)
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let uniquePlaces = Array(Set(allPlaces)) // 중복 제거
            self.addPlaces(uniquePlaces)
            if uniquePlaces.isEmpty {
                self.delegate?.showNoResultsMessage()
            }
        }
    }

  

    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        if let item = clusterItem as? CustomClusterItem {
            DispatchQueue.main.async { [weak self] in
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

    func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
        if let clusterItem = marker.userData as? CustomClusterItem {
            marker.icon = createMarkerIcon(with: clusterItem.place.name)
            marker.title = clusterItem.place.name
            marker.snippet = clusterItem.place.formatted_address
        }
    }

    private func createMarkerIcon(with text: String) -> UIImage? {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.textColor = .black
        label.backgroundColor = .clear

        let padding: CGFloat = 8
        let ovalWidth = label.intrinsicContentSize.width + padding * 2
        let ovalHeight = label.intrinsicContentSize.height + padding
        let ovalView = UIView(frame: CGRect(x: 0, y: 0, width: ovalWidth, height: ovalHeight))

        ovalView.backgroundColor = UIColor.clear

        let ovalLayer = CAShapeLayer()
        let ovalPath = UIBezierPath(roundedRect: ovalView.bounds, cornerRadius: ovalHeight / 2)

        ovalLayer.path = ovalPath.cgPath
        ovalLayer.fillColor = UIColor.white.cgColor
        ovalLayer.lineWidth = 2

        ovalView.layer.addSublayer(ovalLayer)
        ovalView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: ovalView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: ovalView.centerYAnchor).isActive = true

        // 텍스트가 보이지 않는 문제 해결을 위해 레이블의 프레임을 강제로 설정
        label.frame = CGRect(x: padding, y: padding / 2, width: label.intrinsicContentSize.width, height: label.intrinsicContentSize.height)

        // 그림자 효과 추가
        ovalView.layer.shadowColor = UIColor.black.cgColor
        ovalView.layer.shadowOpacity = 0.5
        ovalView.layer.shadowOffset = CGSize(width: 0, height: 2)
        ovalView.layer.shadowRadius = 2

        UIGraphicsBeginImageContextWithOptions(ovalView.bounds.size, false, UIScreen.main.scale)
        ovalView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let markerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return markerImage
    }

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        updateMarkersWithSelectedFilters()
    }



}
