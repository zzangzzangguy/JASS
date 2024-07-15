import GoogleMaps
import GoogleMapsUtils
import UIKit
import RxSwift
import RxCocoa

class MapViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let searchQuery: Observable<String>
        let filterSelection: Observable<Set<String>>
        let mapIdleAt: Observable<GMSCameraPosition>
        let markerTapped: Observable<GMSMarker>
        let zoomIn: Observable<Void>
        let zoomOut: Observable<Void>
    }

    struct Output {
        let places: Driver<[Place]>
        let filteredPlaces: Driver<[Place]>
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String?>
        let shouldUpdateMarkers: Driver<Void>
        let currentZoom: Driver<Float>
        let locationTitle: Driver<String>
        let showPlaceDetails: Driver<Place>
    }

    var disposeBag = DisposeBag()
    private let placesRelay = BehaviorRelay<[Place]>(value: [])
    private let filteredPlacesRelay = BehaviorRelay<[Place]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorMessageRelay = BehaviorRelay<String?>(value: nil)
    private let currentZoomRelay = BehaviorRelay<Float>(value: 15.0)
    private let locationTitleRelay = BehaviorRelay<String>(value: "")
    private let showPlaceDetailsRelay = PublishRelay<Place>()

    var mapView: GMSMapView
    var placeSearchViewModel: PlaceSearchViewModel
    var clusterManager: ClusterManager
    var coordinator: MapCoordinator?
    var selectedCategories = Set<String>()
    let defaultCategory = "헬스"

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

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.setupInitialState()
            })
            .disposed(by: disposeBag)

        input.searchQuery
            .flatMapLatest { [weak self] query -> Observable<[Place]> in
                guard let self = self else { return .empty() }
                return self.searchPlaces(query: query)
            }
            .bind(to: placesRelay)
            .disposed(by: disposeBag)

        input.filterSelection
            .subscribe(onNext: { [weak self] categories in
                self?.selectedCategories = categories.isEmpty ? [self?.defaultCategory ?? ""] : categories
                self?.filterPlaces()
            })
            .disposed(by: disposeBag)

        input.mapIdleAt
            .subscribe(onNext: { [weak self] position in
                self?.updateMarkersForVisibleRegion(at: position)
                self?.currentZoomRelay.accept(position.zoom)
                self?.updateLocationTitle(for: position.target)
            })
            .disposed(by: disposeBag)

        input.markerTapped
            .subscribe(onNext: { [weak self] marker in
                self?.handleMarkerTap(marker)
            })
            .disposed(by: disposeBag)

        input.zoomIn
            .subscribe(onNext: { [weak self] in
                self?.zoomIn()
            })
            .disposed(by: disposeBag)

        input.zoomOut
            .subscribe(onNext: { [weak self] in
                self?.zoomOut()
            })
            .disposed(by: disposeBag)

        return Output(
            places: placesRelay.asDriver(),
            filteredPlaces: filteredPlacesRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            errorMessage: errorMessageRelay.asDriver(),
            shouldUpdateMarkers: filteredPlacesRelay.map { _ in }.asDriver(onErrorJustReturn: ()),
            currentZoom: currentZoomRelay.asDriver(),
            locationTitle: locationTitleRelay.asDriver(),
            showPlaceDetails: showPlaceDetailsRelay.asDriver(onErrorDriveWith: .empty())
        )
    }

    private func setupInitialState() {
        if let currentLocation = mapView.myLocation {
            let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 15)
            mapView.camera = camera
            updateLocationTitle(for: currentLocation.coordinate)
        }
    }

    private func searchPlaces(query: String) -> Observable<[Place]> {
        isLoadingRelay.accept(true)
        return placeSearchViewModel.searchPlace(input: query, category: selectedCategories.joined(separator: ","), currentLocation: mapView.camera.target)
            .do(onNext: { [weak self] _ in
                self?.isLoadingRelay.accept(false)
            }, onError: { [weak self] error in
                self?.isLoadingRelay.accept(false)
                self?.errorMessageRelay.accept(error.localizedDescription)
            })
    }

    private func filterPlaces() {
        let filtered = selectedCategories.isEmpty ? placesRelay.value : placesRelay.value.filter { place in
            guard let types = place.types else { return false }
            return !Set(types).isDisjoint(with: selectedCategories)
        }
        filteredPlacesRelay.accept(filtered)
    }

    private func updateMarkersForVisibleRegion(at position: GMSCameraPosition) {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        clusterManager.updateMarkersWithSelectedFilters()

        if filteredPlacesRelay.value.isEmpty {
            errorMessageRelay.accept("현재 화면에 표시된 장소가 없습니다.")
        }
    }

    private func handleMarkerTap(_ marker: GMSMarker) {
        guard let place = marker.userData as? Place else { return }
        showPlaceDetailsRelay.accept(place)
    }

    private func zoomIn() {
        let newZoom = min(mapView.maxZoom, mapView.camera.zoom + 1)
        mapView.animate(toZoom: newZoom)
    }

    private func zoomOut() {
        let newZoom = max(mapView.minZoom, mapView.camera.zoom - 1)
        mapView.animate(toZoom: newZoom)
    }

    private func updateLocationTitle(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            if let placemark = placemarks?.first {
                let locationTitle = "\(placemark.locality ?? "") \(placemark.subLocality ?? "")"
                self?.locationTitleRelay.accept(locationTitle)
            }
        }
    }

    func updateMarkersWithSearchResults(_ places: [Place]) {
        placesRelay.accept(places)
        filterPlaces()
        clusterManager.addPlaces(filteredPlacesRelay.value)
    }
}
