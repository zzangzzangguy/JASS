import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit
import Toast

class MapViewController: UIViewController, UISearchBarDelegate, CLLocationManagerDelegate {
    var viewModel: MapViewModel!
    var mapView: GMSMapView!
    var searchController: UISearchController!
    var recentSearchesViewController: RecentSearchesViewController!
    var searchResultsViewController: SearchResultsViewController!
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

    // Custom initializer to inject the PlaceSearchViewModel
    init(viewModel: PlaceSearchViewModel) {
        self.placeSearchViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        setupSearchController()
        setupSearchViews()
        setupMapView()
        setupZoomButtons()
        setupLoadingIndicator()
        viewModel = MapViewModel(mapView: mapView, placeSearchViewModel: placeSearchViewModel, navigationController: navigationController)
        clusterManager = ClusterManager(mapView: mapView, navigationController: self.navigationController)
        clusterManager.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2000
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        tabBarController?.tabBar.isHidden = true

        searchRecentViewModel.updateRecentSearches = { [weak self] in
            DispatchQueue.main.async {
                self?.recentSearchesViewController.updateSearchHistoryViews()
            }
        }

        hideKeyboardWhenTappedAround()
    }

    private func applyFilter(filter: String, category: String) {
        showLoadingIndicator()
        placeSearchViewModel.searchPlace(input: filter, category: category) { [weak self] places in
            guard let self = self else { return }
            self.hideLoadingIndicator()
            self.viewModel.places = places
            self.viewModel.filterPlaces()
            self.updateMapMarkers()
            if places.isEmpty {
                self.showToast("필터링된 장소가 없습니다.")
            }
        }
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
        print("현재 줌레벨\(mapView.camera.zoom)")
    }

    private func setupSearchViews() {
        recentSearchesViewController = RecentSearchesViewController()
        recentSearchesViewController.searchRecentViewModel = searchRecentViewModel
        recentSearchesViewController.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchController.searchBar.text = query
            self.searchPlace(query)
        }
        addChild(recentSearchesViewController)
        view.addSubview(recentSearchesViewController.view)
        recentSearchesViewController.view.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview()
        }
        recentSearchesViewController.didMove(toParent: self)
        recentSearchesViewController.view.isHidden = true

        searchResultsViewController = SearchResultsViewController()
        searchResultsViewController.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: self)
        searchResultsViewController.mapViewModel = viewModel // 추가된 부분
        searchResultsViewController.delegate = self // 추가된 부분
        addChild(searchResultsViewController)
        view.addSubview(searchResultsViewController.view)
        searchResultsViewController.view.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview()
        }
        searchResultsViewController.didMove(toParent: self)
        searchResultsViewController.view.isHidden = true
    }

    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        searchController.searchBar.endEditing(true)
    }
    private func setupNavigationBarItems() {
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

    private func setupSearchRecentViewModel() {
        searchRecentViewModel.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchController.searchBar.text = query
            self.searchPlace(query)
        }
    }

    private func searchPlace(_ query: String) {
        let category = selectedCategory ?? defaultCategory
        if selectedCategory == nil {
            showToast("필터가 적용되지 않았습니다. 기본 카테고리로 검색합니다.")
        }
        placeSearchViewModel.searchPlace(input: query, category: category) { [weak self] places in
            guard let self = self else { return }

            self.viewModel.places = places

            if let currentLocation = self.locationManager.location?.coordinate {
                let group = DispatchGroup()

                for (index, place) in self.viewModel.places.enumerated() {
                    group.enter()
                    self.placeSearchViewModel.calculateDistances(from: currentLocation, to: place.coordinate) { distance in
                        self.viewModel.places[index].distanceText = distance
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    self.searchResultsViewController.update(with: self.viewModel.places)
                    self.showSearchResultsView()
                }
            } else {
                self.searchResultsViewController.update(with: places)
                self.showSearchResultsView()
            }
        }
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

    @objc private func zoomIn() {
        let currentZoom = mapView.camera.zoom
        if currentZoom < mapView.maxZoom {
            mapView.animate(toZoom: currentZoom + 1)
            updateZoomButtonsState()
            print("줌레벨: \(mapView.camera.zoom)")
        }
    }

    @objc private func zoomOut() {
        let currentZoom = mapView.camera.zoom
        if currentZoom > mapView.minZoom {
            mapView.animate(toZoom: currentZoom - 1)
            updateZoomButtonsState()
            print("줌레벨: \(mapView.camera.zoom)")
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

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        updateZoomButtonsState()
        if selectedCategory == nil {
            showToast("선택된 필터가 없습니다. 필터를 확인해주세요.")
        }
        clusterManager.updateMarkersWithSelectedFilters()
        if viewModel.filteredPlaces.isEmpty {
            showToast("현재 화면에 표시된 장소가 없습니다.")
        }
        showMarkersToast()
    }

    private func showMarkersToast() {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        let visibleMarkers = viewModel.filteredPlaces.filter { place in
            bounds.contains(place.coordinate)
        }
        if visibleMarkers.isEmpty {
            showToast("현재 화면에 표시된 장소가 없습니다.")
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let category = self.selectedCategory ?? self.defaultCategory
            self.placeSearchViewModel.searchPlace(input: searchText, category: category) { places in
                self.searchResultsViewController.view.isHidden = places.isEmpty
                self.recentSearchesViewController.view.isHidden = !places.isEmpty
            }
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchRecentViewModel.saveSearchHistory(query: searchText)
            showLoadingIndicator()
            let category = selectedCategory ?? defaultCategory

            print("searchBarSearchButton 실행 - query: \(searchText), category: \(category)")

            placeSearchViewModel.searchPlace(input: searchText, category: category) { [weak self] places in
                guard let self = self else { return }

                self.viewModel.places = places
                self.viewModel.filterPlaces()
                self.hideLoadingIndicator()

                if let currentLocation = self.locationManager.location?.coordinate {
                    let group = DispatchGroup()

                    for (index, place) in self.viewModel.places.enumerated() {
                        group.enter()
                        self.placeSearchViewModel.calculateDistances(from: currentLocation, to: place.coordinate) { distance in
                            self.viewModel.places[index].distanceText = distance
                            group.leave()
                        }
                    }

                    group.notify(queue: .main) {
                        self.searchResultsViewController.update(with: self.viewModel.places)
                        self.showSearchResultsView()
                    }
                } else {
                    self.searchResultsViewController.update(with: places)
                    self.showSearchResultsView()
                }
            }
        }
    }

    private func showSearchResultsView() {
        recentSearchesViewController.view.isHidden = true
        searchResultsViewController.view.isHidden = false
        mapView.isHidden = true
    }

    func didSelectPlace(_ place: Place) {
        searchRecentViewModel.saveSearchHistory(query: place.name)

        viewModel.places = [place]
        viewModel.updateSelectedPlaceMarker(for: place)

        let camera = GMSCameraPosition.camera(withLatitude: place.geometry.location.lat, longitude: place.geometry.location.lng, zoom: 13.0)
        viewModel.mapView.camera = camera
        searchController.isActive = false
        viewModel.mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchResultsViewController.view.isHidden = true
        recentSearchesViewController.view.isHidden = true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchResultsViewController.view.isHidden = true
        recentSearchesViewController.view.isHidden = true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        viewModel.mapView.isHidden = true
        zoomInButton.isHidden = true
        zoomOutButton.isHidden = true

        if searchBar.text?.isEmpty ?? true {
            recentSearchesViewController.view.isHidden = false
        } else {
            recentSearchesViewController.view.isHidden = true
        }
    }

    func handleSearchResults(_ places: [Place]) {
        viewModel.places = places
        viewModel.filteredPlaces = places
        viewModel.filterPlaces()
        searchResultsViewController.viewModel?.loadSearchResults(with: viewModel.filteredPlaces)
    }

    func updateMapMarkers() {
        viewModel.updateMapMarkers()
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
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        updateZoomButtonsState()
        clusterManager.updateMarkersWithSelectedFilters()
        print("현재 줌레벨: \(mapView.camera.zoom)")
        let targetLocation = CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)
        print("지도 중심 위치: \(targetLocation.coordinate.latitude), \(targetLocation.coordinate.longitude)")
        updateLocationTitle(location: targetLocation)
        throttleReverseGeocode(location: targetLocation)
    }

    func updateLocationTitle(location: CLLocation) {
        let geocoder = CLGeocoder()
        print("지오코딩 시작: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            if let placemark = placemarks?.first {
                let locationTitle = "\(placemark.locality ?? "") \(placemark.subLocality ?? "")"
                print("지오코딩 결과: \(locationTitle)")

                DispatchQueue.main.async {
                    self.navigationItem.title = locationTitle
                }
            }
        }
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let place = marker.userData as? Place else {
            print("오류: 마커의 userData가 올바르게 설정되지 않았습니다.")
            return false
        }

        print("마커 클릭됨: \(place.name)")
        if let navigationController = navigationController {
            let gymDetailVC = GymDetailViewController(place: place)
            navigationController.pushViewController(gymDetailVC, animated: true)
        } else {
            print("오류: Navigation controller가 nil입니다.")
        }

        return true
    }
}

extension MapViewController: FilterViewDelegate {
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: [String]) {
        viewModel.selectedCategories = categories.isEmpty ? [defaultCategory] : Set(categories)

        let query = categories.joined(separator: " ")
        print("선택된 카테고리 쿼리: \(query)")

        showLoadingIndicator()
        selectedCategory = categories.first
        guard let category = selectedCategory else { return }
        placeSearchViewModel.searchPlace(input: query, category: category) { [weak self] places in
            guard let self = self else { return }
            self.hideLoadingIndicator()

            self.viewModel.places = places
            self.viewModel.filterPlaces()
            clusterManager.updateMarkersWithSelectedFilters()
            self.updateMapMarkers()

            if places.isEmpty {
                self.showToast("필터링된 장소가 없습니다.")
            }
        }

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
}

extension MapViewController: ClusterManagerDelegate {
    func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, query: String, completion: @escaping ([Place]) -> Void) {
        placeSearchViewModel.searchPlacesInBounds(bounds, query: query, completion: completion)
    }

    func selectedFilters() -> Set<String> {
        return viewModel.selectedCategories
    }

    func showNoResultsMessage() {
        if viewModel.filteredPlaces.isEmpty {
            ToastManager.showToast(message: "현재 화면에 표시된 장소가 없습니다.", in: self)
        }
    }

    func clusterManager(_ clusterManager: ClusterManager, didSelectPlace place: Place) {
        let gymDetailVC = GymDetailViewController(place: place)
        navigationController?.pushViewController(gymDetailVC, animated: true)
    }
}

extension MapViewController: SearchResultsViewDelegate {
    func showToastForFavorite(place: Place, isAdded: Bool) {
        let message = isAdded ? "즐겨찾기에 추가되었습니다." : "즐겨찾기에서 제거되었습니다."
        view.makeToast(message)
    }
}
