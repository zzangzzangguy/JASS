import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit
import Toast

class MapViewController: UIViewController, UISearchBarDelegate, CLLocationManagerDelegate {
    var viewModel: MapViewModel!
    var mapView: GMSMapView!
    var searchController: UISearchController!
    var recentSearchesView: RecentSearchesView!
    var searchResultsView: SearchResultsView!
    var searchTask: DispatchWorkItem?
    var filterContainerView: UIView!
    var filterStackView: UIStackView!
    var filterButton: UIButton!
    var placeSearchViewModel = PlaceSearchViewModel()
    var searchRecentViewModel = SearchRecentViewModel()
    let zoomInButton = UIButton(type: .system)
    let zoomOutButton = UIButton(type: .system)
    var clusterManager: ClusterManager!
    let locationManager = CLLocationManager()

    private var selectedCategory: String?

    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var filterView: FilterViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        setupSearchViews()
        setupMapView()
        setupZoomButtons()
        setupLoadingIndicator()
        viewModel = MapViewModel(mapView: mapView, placeSearchViewModel: placeSearchViewModel, navigationController: navigationController)
        clusterManager = ClusterManager(mapView: mapView, navigationController: self.navigationController)
        clusterManager.delegate = self

        setupFilterView()
        setupFilterButtonView()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        searchRecentViewModel.updateRecentSearches = { [weak self] in
            DispatchQueue.main.async {
                self?.recentSearchesView.updateSearchHistoryViews()
            }
        }

//        updateAppearance()
    }

    private func applyFilter(filter: String, category: String) {
        showLoadingIndicator()
        placeSearchViewModel.searchPlace(input: filter, category: category) { [weak self] places in
            guard let self = self else { return }
            self.hideLoadingIndicator()
            self.viewModel.places = places
            self.viewModel.filterPlaces()
            self.updateClusteringWithSelectedCategories()
            self.updateMapMarkers()
        }
    }

    private func setupFilterButtonView() {
        filterContainerView = UIView()
        filterStackView = UIStackView()
        filterButton = UIButton()

        filterButton.setTitleColor(.black, for: .normal)
        filterButton.setTitle("필터", for: .normal)
        filterButton.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        filterButton.tintColor = .systemBlue
        filterButton.layer.cornerRadius = 16
        filterButton.layer.borderWidth = 1.0
        filterButton.layer.borderColor = UIColor.lightGray.cgColor
        filterButton.addTarget(self, action: #selector(showFilterView), for: .touchUpInside)

        filterContainerView.backgroundColor = UIColor.white
        view.addSubview(filterContainerView)
        filterContainerView.addSubview(filterButton)
        filterContainerView.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(50)
        }

        filterButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.leading.equalToSuperview().inset(20)
            $0.width.equalTo(100)
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
    }

    private func setupSearchViews() {
        recentSearchesView = RecentSearchesView()
        recentSearchesView.searchRecentViewModel = searchRecentViewModel
        recentSearchesView.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchController.searchBar.text = query
            self.searchPlace(query)
        }
        view.addSubview(recentSearchesView)
        recentSearchesView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview()
        }
        recentSearchesView.isHidden = true

        searchResultsView = SearchResultsView()
        searchResultsView.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: self)
        searchResultsView.delegate = self
        view.addSubview(searchResultsView)
        searchResultsView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview()
        }
        searchResultsView.isHidden = true
    }

    private func setupFilterView() {
        let filterViewController = FilterViewController()
        filterViewController.delegate = self
        self.filterView = filterViewController
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
        self.navigationItem.title = "검색"

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
        guard let category = selectedCategory else { return }
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
                    self.searchResultsView.update(with: self.viewModel.places)
                    self.showSearchResultsView()
                }
            } else {
                self.searchResultsView.update(with: places)
                self.showSearchResultsView()
//                mapView.clear()

            }
        }
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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard let category = self.selectedCategory else { return }
            self.placeSearchViewModel.searchPlace(input: searchText, category: category) { places in
                self.searchResultsView.isHidden = places.isEmpty
                self.recentSearchesView.isHidden = !places.isEmpty
                self.filterContainerView.isHidden = !places.isEmpty
            }
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchRecentViewModel.saveSearchHistory(query: searchText)
            showLoadingIndicator()
            guard let category = selectedCategory else { return }
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
                        self.searchResultsView.update(with: self.viewModel.places)
                        self.showSearchResultsView()
                    }
                } else {
                    self.searchResultsView.update(with: places)
                    self.showSearchResultsView()
                }
            }
        }
    }

    private func showSearchResultsView() {
        recentSearchesView.isHidden = true
        searchResultsView.isHidden = false
        mapView.isHidden = true
    }

    func didSelectPlace(_ place: Place) {

        searchRecentViewModel.saveSearchHistory(query: place.name)
        viewModel.places = [place]
        viewModel.updateSelectedPlaceMarker(for: place )


        let camera = GMSCameraPosition.camera(withLatitude: place.geometry.location.lat, longitude: place.geometry.location.lng, zoom: 13.0)
        viewModel.mapView.camera = camera
        searchController.isActive = false
        viewModel.mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchResultsView.isHidden = true
        recentSearchesView.isHidden = true
        filterContainerView.isHidden = false
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filterContainerView.isHidden = false
        searchResultsView.isHidden = true
        recentSearchesView.isHidden = true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        viewModel.mapView.isHidden = true
        zoomInButton.isHidden = true
        zoomOutButton.isHidden = true
        filterContainerView.isHidden = true

        if searchBar.text?.isEmpty ?? true {
            recentSearchesView.isHidden = false
        } else {
            recentSearchesView.isHidden = true
        }
    }

    func handleSearchResults(_ places: [Place]) {
        viewModel.places = places
        viewModel.filteredPlaces = places
        viewModel.filterPlaces()
        searchResultsView.viewModel?.loadSearchResults(with: viewModel.filteredPlaces)

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

extension MapViewController: FilterViewDelegate {
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: [String]) {
        viewModel.selectedCategories = Set(categories)

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
