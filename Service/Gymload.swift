//
//  Gymload.swift
//  JASS
//
//  Created by 김기현 on 2/13/24.
//

import Foundation
import GoogleMaps

class Gymload {
    private let mapView: GMSMapView
     private let placeSearchViewModel: PlaceSearchViewModel

     init(mapView: GMSMapView, placeSearchViewModel: PlaceSearchViewModel) {
         self.mapView = mapView
         self.placeSearchViewModel = placeSearchViewModel
     }
    func searchGymsNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, completion: @escaping ([Place]) -> Void) {
        let bounds = GMSCoordinateBounds(coordinate: coordinate, coordinate: coordinate)
        placeSearchViewModel.searchPlacesNearCoordinate(coordinate, radius: radius, bounds: bounds) { places in
            completion(places)
        }
    }

    func loadGymsInBounds() {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        let center = mapView.camera.target
        let width = mapView.frame.width
        let height = mapView.frame.height
        let northEastPoint = CGPoint(x: center.latitude + width / 2, y: center.longitude + height / 2)
        let southWestPoint = CGPoint(x: center.latitude - width / 2, y: center.longitude - height / 2)

        let northEastCoordinate = mapView.projection.coordinate(for: northEastPoint)
        let southWestCoordinate = mapView.projection.coordinate(for: southWestPoint)

        placeSearchViewModel.searchPlacesInBounds(GMSCoordinateBounds(coordinate: southWestCoordinate, coordinate: northEastCoordinate)) { [weak self] places in
            for place in places {
                self?.addMarker(for: place)
            }
        }
        func searchGymsNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, completion: @escaping ([Place]) -> Void) {
            let bounds = GMSCoordinateBounds(coordinate: coordinate, coordinate: coordinate)

            placeSearchViewModel.searchPlacesNearCoordinate(coordinate, radius: radius, bounds: bounds) { places in
                completion(places)
            }
        }
    }
    

     private func addMarker(for place: Place) {
         let marker = GMSMarker()
         marker.position = CLLocationCoordinate2D(latitude: place.geometry.location.lat, longitude: place.geometry.location.lng)
         marker.title = place.name
         marker.snippet = place.isGym ? "헬스장" : "일반 위치"

         var iconName: String
         if place.name.lowercased().contains("gym") || place.name.lowercased().contains("fitness") || place.name.lowercased().contains("피트니스") || place.name.lowercased().contains("휘트니스") || place.name.lowercased().contains("헬스") {
             iconName = "gym"
         } else if place.name.lowercased().contains("pilates") || place.name.lowercased().contains("필라테스") {
             iconName = "pilates"
         } else {
             iconName = "default_marker"
         }

         if let iconImage = UIImage(named: iconName)?.scaledToSize(size: CGSize(width: 35, height: 35)) {
             marker.icon = iconImage
         } else {
             print("\(iconName) 아이콘 이미지를 불러오는 데 실패했습니다.")
         }

         marker.map = mapView
     }
 }
