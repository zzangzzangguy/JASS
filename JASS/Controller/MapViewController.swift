import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit
import Toast

class MapViewController: UIViewController {
    // View Model 및 각종 뷰 요소 선언
    var viewModel: MapViewModel!
    var mapView: GMSMapView!
    private let searchController = UISearchController(searchResultsController: nil)
    private let filterButton = UIButton(type: .system)
    var recentSearchesView: RecentSearchesView!
    var searchResultsView: SearchResultsView!
    var placeSearchViewModel = PlaceSearchViewModel()
    var searchRecentViewModel = SearchRecentViewModel()
    let zoomInButton = UIButton(type: .system)
    let zoomOutButton = UIButton(type: .system)
    var clusterManager: ClusterManager!
    let locationManager = CLLocationManager()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var filterView: FilterViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initializeViewModel()
        setupLocationManager()
    }

    private func setupUI() {
        setupMapView()
        setupSearchControllerAndFilterButton()
        setupSearchViews()
        setupZoomButtons()
        setupLoadingIndicator()
    }

    private func initializeViewModel() {
        viewModel = MapViewModel(mapView: mapView, placeSearchViewModel: placeSearchViewModel, navigationController: navigationController)
        clusterManager = ClusterManager(mapView: mapView, navigationController: self.navigationController)
        clusterManager.delegate = self

        searchRecentViewModel.updateRecentSearches = { [weak self] in
            DispatchQueue.main.async {
                self?.recentSearchesView.updateSearchHistoryViews()
            }
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func setupSearchControllerAndFilterButton() {
        // 검색 컨트롤러 설정
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "검색어를 입력해 주세요."
        definesPresentationContext = true

        navigationItem.searchController = searchController
           navigationItem.hidesSearchBarWhenScrolling = false

        // 필터 버튼 설정
        filterButton.setTitle("필터", for: .normal)
        filterButton.setTitleColor(.black, for: .normal)
        filterButton.tintColor = .systemBlue
        filterButton.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        filterButton.addTarget(self, action: #selector(showFilterView), for: .touchUpInside)

        let searchAndFilterView = UIView()
           searchAndFilterView.addSubview(searchController.searchBar)
           searchAndFilterView.addSubview(filterButton)

        // 검색 바와 필터 버튼을 뷰에 추가
        view.addSubview(searchController.searchBar)
        view.addSubview(filterButton)

        // 오토레이아웃 설정
        searchController.searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview().inset(10)
            make.height.equalTo(50)
        }

        filterButton.snp.makeConstraints { make in
            make.top.equalTo(searchController.searchBar.snp.bottom).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }
        view.addSubview(searchAndFilterView)
          searchAndFilterView.snp.makeConstraints { make in
              make.left.right.equalToSuperview()
              make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
              make.height.equalTo(44)
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
        setInitialCameraPosition()
    }

    private func setInitialCameraPosition() {
        if let currentLocation = locationManager.location {
            let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 15)
            mapView.camera = camera
        }
        let minZoomLevel: Float = 13.0
        let maxZoomLevel: Float = 20.0
        mapView.setMinZoom(minZoomLevel, maxZoom: maxZoomLevel)
    }

    private func setupSearchViews() {
        recentSearchesView = RecentSearchesView()
        recentSearchesView.searchRecentViewModel = searchRecentViewModel
        recentSearchesView.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchController.searchBar.text = query
            self.updateSearchResults(for: self.searchController)
        }
        view.addSubview(recentSearchesView)
        recentSearchesView.snp.makeConstraints {
            $0.top.equalTo(filterButton.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview().offset(-100) // 조정 가능
        }
        recentSearchesView.isHidden = true

        searchResultsView = SearchResultsView()
        searchResultsView.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: self)
        searchResultsView.delegate = self
        view.addSubview(searchResultsView)
        searchResultsView.snp.makeConstraints {
            $0.top.equalTo(filterButton.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview().offset(-100) // 조정 가능
        }
        searchResultsView.isHidden = true
    }

    private func setupFilterView() {
        filterView = FilterViewController()
        filterView?.delegate = self
    }

    @objc private func showFilterView(_ sender: Any) {
        guard let filterView = filterView else { return }
        present(filterView, animated: true, completion: nil)
    }

    private func configureZoomButton(button: UIButton, systemName: String, action: Selector) {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium, scale: .large)
        button.setImage(UIImage(systemName: systemName, withConfiguration: imageConfig), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .blue
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.5
        button.layer.shadowRadius = 2
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }

    private func setupZoomButtons() {
        configureZoomButton(button: zoomInButton, systemName: "plus.magnifyingglass", action: #selector(zoomIn))
        configureZoomButton(button: zoomOutButton, systemName: "minus.magnifyingglass", action: #selector(zoomOut))

        zoomInButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(100)
            $0.width.height.equalTo(40)
        }
        zoomOutButton.snp.makeConstraints {
            $0.trailing.equalTo(zoomInButton.snp.trailing)
            $0.bottom.equalTo(zoomInButton.snp.top).offset(-15)
            $0.width.height.equalTo(40)
        }

        updateZoomButtonsState()
    }

    @objc private func zoomIn() {
        let currentZoom = mapView.camera.zoom
        if currentZoom < mapView.maxZoom {
            mapView.animate(toZoom: currentZoom + 1)
        }
        updateZoomButtonsState()
    }

    @objc private func zoomOut() {
        let currentZoom = mapView.camera.zoom
        if currentZoom > mapView.minZoom {
            mapView.animate(toZoom: currentZoom - 1)
        }
        updateZoomButtonsState()
    }

    private func updateZoomButtonsState() {
        zoomInButton.isEnabled = mapView.camera.zoom < mapView.maxZoom
        zoomOutButton.isEnabled = mapView.camera.zoom > mapView.minZoom
        zoomInButton.backgroundColor = zoomInButton.isEnabled ? .blue : .gray
        zoomOutButton.backgroundColor = zoomOutButton.isEnabled ? .blue : .gray
    }

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        updateZoomButtonsState()
        showMarkersToast()
        clusterManager.updateMarkersWithSelectedFilters()
        if viewModel.filteredPlaces.isEmpty {
            showToast("현재 화면에 표시된 장소가 없습니다.")
        }
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

    func handleSearchResults(_ places: [Place]) {
        viewModel.places = places
        viewModel.filteredPlaces = places
        viewModel.filterPlaces()
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
}

// UISearchResultsUpdating 프로토콜 구현
extension MapViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            recentSearchesView.isHidden = false
            searchResultsView.isHidden = true
            return
        }

        showLoadingIndicator()
        searchRecentViewModel.saveSearchHistory(query: searchText)

        placeSearchViewModel.searchPlace(input: searchText) { [weak self] places in
            guard let self = self else { return }
            self.hideLoadingIndicator()
            self.searchResultsView.update(with: places)
            self.recentSearchesView.isHidden = true
            self.searchResultsView.isHidden = false
            self.mapView.isHidden = true
        }
    }
}

// CLLocationManagerDelegate 프로토콜 구현
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            viewModel.currentLocation = location
        }
    }
}

// GMSMapViewDelegate 프로토콜 구현
extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        updateZoomButtonsState()
        clusterManager.updateMarkersWithSelectedFilters()
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

// FilterViewDelegate 프로토콜 구현
extension MapViewController: FilterViewDelegate {
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: [String]) {
        viewModel.selectedCategories = Set(categories)
        let query = categories.joined(separator: " ")
        showLoadingIndicator()
        placeSearchViewModel.searchPlace(input: query) { [weak self] places in
            guard let self = self else { return }
            self.hideLoadingIndicator()
            self.viewModel.places = places
            self.viewModel.filterPlaces()
            self.updateClusteringWithSelectedCategories()
            self.updateMapMarkers()
        }
        dismiss(animated: true, completion: nil)
    }

    private func updateClusteringWithSelectedCategories() {
        let filteredPlaces = viewModel.places.filter { place in
            guard let types = place.types else { return false }
            return !Set(types).isDisjoint(with: Set(viewModel.selectedCategories))
        }

        if filteredPlaces.isEmpty {
            print("필터링된 장소가 없습니다.")
        } else {
            clusterManager.addPlaces(viewModel.places)
        }
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

// ClusterManagerDelegate 프로토콜 구현
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

// SearchResultsViewDelegate 프로토콜 구현
extension MapViewController: SearchResultsViewDelegate {
    func didSelectPlace(_ place: Place) {
        searchRecentViewModel.saveSearchHistory(query: place.name)
        let camera = GMSCameraPosition.camera(withLatitude: place.geometry.location.lat, longitude: place.geometry.location.lng, zoom: 15.0)
        mapView.animate(to: camera)
        mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchResultsView.isHidden = true
        recentSearchesView.isHidden = true
        searchController.dismiss(animated: true, completion: nil)
    }

    func showToastForFavorite(place: Place, isAdded: Bool) {
        let message = isAdded ? "즐겨찾기에 추가되었습니다." : "즐겨찾기에서 제거되었습니다."
        view.makeToast(message)
    }
}
