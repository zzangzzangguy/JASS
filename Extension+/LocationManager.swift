import Foundation
import GoogleMaps

class LocationManager: NSObject, GMSMapViewDelegate {
    static let shared = LocationManager()
    private var mapView: GMSMapView?
    private var currentLocation: CLLocationCoordinate2D?

    private override init() {
        super.init()
    }

    func setMapView(_ mapView: GMSMapView) {
        self.mapView = mapView
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }

    func getCurrentLocation() -> CLLocationCoordinate2D? {
        return currentLocation
    }

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        currentLocation = position.target
    }
}
