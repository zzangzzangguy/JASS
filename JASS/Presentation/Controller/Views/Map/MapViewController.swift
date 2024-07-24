import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces
import SnapKit
import Toast
import RxSwift

class MapViewController: UIViewController, CLLocationManagerDelegate {
    private let disposeBag = DisposeBag()
    weak var coordinator: MapCoordinator?
    var mapView: GMSMapView!
    var searchController: UISearchController!
    var searchTask: DispatchWorkItem?
    var placeSearchViewModel: PlaceSearchViewModel
    var searchRecentViewModel = SearchRecentViewModel()
    let zoomInButton = UIButton(type: .system)
    let zoomOutButton = UIButton(type: .system)
    var clusterManager: ClusterManager!
    let locationManager = CLLocationManager()
    private var geocodeTimer: Timer?
    private var selectedCategory: String?
    private let defaultCategory = "헬스"
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var filterView: FilterViewController?
    private let viewModel: MapViewModel
    private var output: MapViewModel.Output!
    private let filterSelectionSubject = BehaviorSubject<Set<String>>(value: ["헬스"])

    private let mapIdleSubject = PublishSubject<GMSCameraPosition>()
    private let markerTappedSubject = PublishSubject<GMSMarker>()

    init(
        viewModel: MapViewModel,
        coordinator: MapCoordinator?
    ) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        self.placeSearchViewModel = viewModel.placeSearchViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        setupSearchController()
        setupMapView()
        setupZoomButtons()
        setupLoadingIndicator()
        setupBindings()

        clusterManager = ClusterManager(
            mapView: mapView,
            navigationController: self.navigationController,
            coordinator: self.coordinator)
        clusterManager.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2000
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        hideKeyboardWhenTappedAround()
    }

    private func setupBindings() {
        let input = MapViewModel.Input(
            viewDidLoad: .just(()),
            searchButtonClicked: searchController.searchBar.rx.searchButtonClicked
                .withLatestFrom(searchController.searchBar.rx.text.orEmpty)
                .filter { !$0.isEmpty },
            filterSelection: filterSelectionSubject.asObservable(),
            mapIdleAt: mapIdleSubject.asObservable(),
            markerTapped: markerTappedSubject.asObservable(),
            zoomIn: zoomInButton.rx.tap.asObservable(),
            zoomOut: zoomOutButton.rx.tap.asObservable()
        )

        output = viewModel.transform(input: input)

        

        output.places
            .drive(onNext: { [weak self] places in
                self?.updateMapMarkers(with: places)
            })
            .disposed(by: disposeBag)

        output.isLoading
            .drive(loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        output.errorMessage
            .drive(onNext: { [weak self] message in
                if let message = message {
                    self?.showToast(message)
                }
            })
            .disposed(by: disposeBag)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setupMapView() {
        mapView = GMSMapView()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.delegate = self
        view.addSubview(mapView)
        mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        if let currentLocation = locationManager.location {
            let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 13)
            mapView.camera = camera
        }
        let minZoomLevel: Float = 13.0
        let maxZoomLevel: Float = 20.0
        mapView.setMinZoom(minZoomLevel, maxZoom: maxZoomLevel)
    }

    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        searchController.searchBar.endEditing(true)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func setupNavigationBarItems() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonTapped))
        navigationItem.leftBarButtonItem = closeButton

        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease.circle"), style: .plain, target: self, action: #selector(showFilterView))
        navigationItem.rightBarButtonItem = filterButton
    }

    @objc private func showFilterView(_ sender: Any) {
        guard let filterView = filterView else {
            let filterViewController = FilterViewController()
            filterViewController.delegate = self
            self.filterView = filterViewController
            present(filterViewController, animated: true, completion: nil)
            return
        }
        present(filterView, animated: true, completion: nil)
    }

    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "지역, 매장명을 검색해주세요"
        searchController.searchBar.tintColor = UIColor.systemBlue
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func searchPlace(_ query: String) {
        let category = selectedCategory ?? defaultCategory
        if selectedCategory == nil {
            showToast("필터가 적용되지 않았습니다. 기본 카테고리로 검색합니다.")
        }

        placeSearchViewModel.searchPlace(input: query, filters: viewModel.selectedCategories, currentLocation: locationManager.location?.coordinate)


            .subscribe(onNext: { [weak self] places in
                guard let self = self else { return }
                self.updateMapMarkers(with: places)

                if let currentLocation = self.locationManager.location?.coordinate {
                } else {
                    self.updateMapMarkers(with: places)
                }
            }, onError: { error in
            })
            .disposed(by: disposeBag)
    }

    private func setupZoomButtons() {
        configureZoomButton(button: zoomInButton, systemName: "plus.magnifyingglass", action: #selector(zoomIn))
        configureZoomButton(button: zoomOutButton, systemName: "minus.magnifyingglass", action: #selector(zoomOut))

        zoomInButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview().offset(-30)
            $0.width.height.equalTo(40)
        }
        zoomOutButton.snp.makeConstraints {
            $0.leading.equalTo(zoomInButton.snp.leading)
            $0.top.equalTo(zoomInButton.snp.bottom).offset(15)
            $0.width.height.equalTo(40)
        }

        updateZoomButtonsState()
    }

    private func configureZoomButton(button: UIButton, systemName: String, action: Selector) {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium, scale: .large)
        button.setImage(UIImage(systemName: systemName, withConfiguration: imageConfig), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .blue
        button.layer.cornerRadius = 20
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }

    @objc private func zoomIn() {
        let currentZoom = mapView.camera.zoom
        if currentZoom < mapView.maxZoom {
            mapView.animate(toZoom: currentZoom + 1)
            updateZoomButtonsState()
        }
    }

    @objc private func zoomOut() {
        let currentZoom = mapView.camera.zoom
        if currentZoom > mapView.minZoom {
            mapView.animate(toZoom: currentZoom - 1)
            updateZoomButtonsState()
        }
    }

    private func updateZoomButtonsState() {
        let currentZoom = mapView.camera.zoom
        let minZoomLevel: Float = 13.0
        let maxZoomLevel: Float = 20.0

        zoomInButton.isEnabled = currentZoom < maxZoomLevel
        zoomOutButton.isEnabled = currentZoom > minZoomLevel

        zoomInButton.backgroundColor = zoomInButton.isEnabled ? .systemBlue : .lightGray
        zoomOutButton.backgroundColor = zoomOutButton.isEnabled ? .systemBlue : .lightGray
    }

    func updateMapMarkers(with places: [Place]) {
        viewModel.updateMarkersWithSearchResults(places)
    }

    func showLoadingIndicator() {
        loadingIndicator.startAnimating()
    }

    func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            throttleReverseGeocode(location: location)
            locationManager.stopUpdatingLocation()
        }
    }

    private func throttleReverseGeocode(location: CLLocation) {
        geocodeTimer?.invalidate()
        geocodeTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.updateLocationTitle(location: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        showLoadingIndicator()
    }

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        mapIdleSubject.onNext(position)
        updateZoomButtonsState()
        clusterManager.updateMarkersWithSelectedFilters()
        if viewModel.selectedCategories.isEmpty {
               return
           }
        let targetLocation = CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)
        updateLocationTitle(location: targetLocation)
        throttleReverseGeocode(location: targetLocation)
        hideLoadingIndicator()
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        markerTappedSubject.onNext(marker)
        guard let place = marker.userData as? Place else {
            print("오류: 마커의 userData가 올바르게 설정되지 않았습니다.")
            return false
        }

        let gymDetailVC = GymDetailViewController(viewModel: GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: placeSearchViewModel))
        gymDetailVC.modalPresentationStyle = .fullScreen
        present(gymDetailVC, animated: true, completion: nil)
        return true
    }

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        updateZoomButtonsState()
        if selectedCategory == nil {
            showToast("선택된 필터가 없습니다. 필터를 확인해주세요.")
        }
        clusterManager.updateMarkersWithSelectedFilters()
        output.filteredPlaces
            .drive(onNext: { [weak self] places in
                if places.isEmpty {
                    self?.showToast("현재 화면에 표시된 장소가 없습니다.")
                }
            })
            .disposed(by: disposeBag)
        showMarkersToast()
    }

    func updateLocationTitle(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            if let placemark = placemarks?.first {
                let locationTitle = "\(placemark.locality ?? "") \(placemark.subLocality ?? "")"
                DispatchQueue.main.async {
                    self.navigationItem.title = locationTitle
                }
            }
        }
    }
}

extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchRecentViewModel.saveSearchHistory(query: searchText)
            showLoadingIndicator()
            placeSearchViewModel.searchPlace(input: searchText, filters: viewModel.selectedCategories, currentLocation: locationManager.location?.coordinate)
                .subscribe(onNext: { [weak self] places in
                    guard let self = self, let firstPlace = places.first else {
                        self?.showToast("검색 결과가 없습니다.")
                        self?.hideLoadingIndicator()
                        return
                    }
                    self.hideLoadingIndicator()
                    self.updateMapMarkers(with: places)
                    let camera = GMSCameraPosition.camera(withLatitude: firstPlace.geometry.location.lat,
                                                          longitude: firstPlace.geometry.location.lng,
                                                          zoom: 15.0)
                    self.mapView.animate(to: camera)
                }, onError: { [weak self] error in
                    self?.hideLoadingIndicator()
                    self?.showToast("검색 중 오류가 발생했습니다.")
                })
                .disposed(by: disposeBag)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
}

extension MapViewController: FilterViewDelegate {
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: Set<String>) {
        filterSelectionSubject.onNext(categories)

        let query = categories.joined(separator: " ")

        showLoadingIndicator()
        selectedCategory = categories.first
                guard let category = selectedCategory else { return }

        placeSearchViewModel.searchPlace(input: query, filters: viewModel.selectedCategories, currentLocation: locationManager.location?.coordinate)

                  .subscribe(onNext: { [weak self] places in
                        guard let self = self else { return }
                        self.hideLoadingIndicator()
                        self.updateMapMarkers(with: places)
                        self.clusterManager.updateMarkersWithSelectedFilters()
                        self.updateMapMarkers(with: places)

                        if places.isEmpty {
                            self.showToast("필터링된 장소가 없습니다.")
                        }
                    }, onError: { error in
                        // 에러 처리
                        self.hideLoadingIndicator()
                    })
                    .disposed(by: disposeBag)
                dismiss(animated: true, completion: nil)
            }

            func filterViewDidCancel(_ filterView: FilterViewController) {
                dismiss(animated: true, completion: nil)
            }
        }

        extension MapViewController {
            func showToast(_ message: String) {
                view.makeToast(message)
            }

            private func showMarkersToast() {
                let visibleRegion = mapView.projection.visibleRegion()
                let bounds = GMSCoordinateBounds(region: visibleRegion)
                output.filteredPlaces
                    .drive(onNext: { [weak self] places in
                        let visibleMarkers = places.filter { place in
                            bounds.contains(place.coordinate)
                        }
                        if visibleMarkers.isEmpty {
                            self?.showToast("현재 화면에 표시된 장소가 없습니다.")
                        }
                    })
                    .disposed(by: disposeBag)
            }
        }

        extension MapViewController: ClusterManagerDelegate {
            func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, query: String, completion: @escaping ([Place]) -> Void) {
                placeSearchViewModel.searchPlacesInBounds(bounds: bounds, query: query, completion: completion)
            }

            func selectedFilters() -> Set<String> {
                return viewModel.selectedCategories
            }

            func showNoResultsMessage() {
                output.filteredPlaces
                    .drive(onNext: { [weak self] places in
                        if places.isEmpty {
                            self?.showToast("현재 화면에 표시된 장소가 없습니다.")
                        }
                    })
                    .disposed(by: disposeBag)
            }

            func clusterManager(_ clusterManager: ClusterManager, didSelectPlace place: Place) {
                let gymDetailVC = GymDetailViewController(viewModel: GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: placeSearchViewModel))
                navigationController?.pushViewController(gymDetailVC, animated: true)
            }
        }
