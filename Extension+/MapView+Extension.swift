//
//  MapView+Extension.swift
//  JASS
//
//  Created by 김기현 on 1/28/24.
//

import UIKit
import GoogleMaps


extension GMSMapView {

    func addCustomMarker(at location: CLLocationCoordinate2D, title: String? = nil, snippet: String? = nil, iconName: String? = nil) {
        let marker = GMSMarker()
        marker.position = location
        marker.title = title
        marker.snippet = snippet
        if let iconName = iconName, let icon = UIImage(named: iconName)?.scaledToSize(size: CGSize(width: 30, height: 30)) {
            marker.icon = icon
        }
        marker.map = self
    }

    func animateToLocation(_ location: CLLocationCoordinate2D, zoomLevel: Float = 15.0) {
        let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: zoomLevel)
        self.animate(to: camera)
    }

    func showBoundsOnMap(bounds: GMSCoordinateBounds) {
        let rect = GMSMutablePath()
        rect.add(CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude))
        rect.add(CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.northEast.longitude))
        rect.add(CLLocationCoordinate2D(latitude: bounds.northEast.latitude, longitude: bounds.northEast.longitude))
        rect.add(CLLocationCoordinate2D(latitude: bounds.northEast.latitude, longitude: bounds.southWest.longitude))

        let polygon = GMSPolygon(path: rect)
        polygon.fillColor = UIColor(red: 0.25, green: 0, blue: 0, alpha: 0.2)
        polygon.strokeColor = .red
        polygon.strokeWidth = 2
        polygon.map = self
    }
}
