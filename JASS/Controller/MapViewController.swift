import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit
import GooglePlaces
import Then

class MapViewController: UIViewController, UISearchBarDelegate, SearchResultsViewDelegate {
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

    private var filterView: FilterViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupSearchViews()
        setupSearchController()
        setupZoomButtons()
        setupStatusBarBackground()
        setupFilterButtonView()
        viewModel = MapViewModel(mapView: mapView, placeSearchViewModel: placeSearchViewModel)
        clusterManager = ClusterManager(mapView: mapView)
        clusterManager.delegate = self

        setupFilterView()
        setupFilterButton()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
//        mapView.setMinZoom(4, maxZoom: mapView.maxZoom)

        searchRecentViewModel.updateRecentSearches = { [weak self] in
            DispatchQueue.main.async {
                self?.recentSearchesView.updateSearchHistoryViews()
            }
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

        filterContainerView.backgroundColor = .white
        view.addSubview(filterContainerView)
        filterContainerView.addSubview(filterButton)

        filterContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }

        filterButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.leading.equalToSuperview().inset(20)
            $0.width.equalTo(100)
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
                let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 15)
                mapView.camera = camera
            }
        let minZoomLevel: Float = 15.0  // 원하는 최소 줌 레벨 값으로 설정
        let maxZoomLevel: Float = 20.0  // 원하는 최대 줌 레벨 값으로 설정

        mapView.setMinZoom(minZoomLevel, maxZoom: maxZoomLevel)

    }

    private func setupSearchViews() {
        recentSearchesView = RecentSearchesView()
        recentSearchesView.searchRecentViewModel = searchRecentViewModel
        view.addSubview(recentSearchesView)
        recentSearchesView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview()
        }
        recentSearchesView.isHidden = true

        searchResultsView = SearchResultsView()
        searchResultsView.viewModel = placeSearchViewModel
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
        let filterView = FilterViewController()
        filterView.delegate = self
        self.filterView = filterView
    }

    private func setupFilterButton() {
        filterButton.addTarget(self, action: #selector(showFilterView(_:)), for: .touchUpInside)
    }

    @objc private func showFilterView(_ sender: Any) {
        guard let filterView = filterView else { return }
        present(filterView, animated: true, completion: nil)
    }

    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "지역, 매장명을 검색해주세요"
        navigationItem.searchController = searchController
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
    }

    private func setupStatusBarBackground() {
        let statusBarBackgroundView = UIView()
        statusBarBackgroundView.backgroundColor = .white
        view.addSubview(statusBarBackgroundView)
        statusBarBackgroundView.snp.makeConstraints {
            $0.top.equalTo(view.snp.top)
            $0.left.right.equalTo(view)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
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

    @objc private func zoomIn() {
        let currentZoom = mapView.camera.zoom
        if currentZoom < mapView.maxZoom {
            mapView.animate(toZoom: currentZoom + 1)
        }
    }

    @objc private func zoomOut() {
        let currentZoom = mapView.camera.zoom
        if currentZoom > mapView.minZoom {
            mapView.animate(toZoom: currentZoom - 1)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.placeSearchViewModel.searchPlace(input: searchText) { places in
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
            if let currentLocation = viewModel.currentLocation {
                placeSearchViewModel.searchPlace(input: searchText) { [weak self] places in
//                placeSearchViewModel.searchPlacesNearCoordinate(currentLocation.coordinate, radius: 5000, types: [searchText]) { [weak self] places in
                    guard let self = self else { return }
                    self.viewModel.places = places
                    self.viewModel.filterPlaces()

                    // 검색 결과를 searchResultsView에 업데이트하고 표시
                    self.searchResultsView.update(with: places)
                    self.showSearchResultsView()

                    // 지도에 마커 업데이트
//                    self.updateMapMarkers()
                }
            }
        }
    }
    private func showSearchResultsView() {
        recentSearchesView.isHidden = true
        searchResultsView.isHidden = false
        mapView.isHidden = true
        filterContainerView.isHidden = true
    }

    func didSelectPlace(_ place: Place) {
        searchRecentViewModel.saveSearchHistory(query: place.name)
        print("맵뷰 로드짐")

        let camera = GMSCameraPosition.camera(withLatitude: place.geometry.location.lat, longitude: place.geometry.location.lng, zoom: 15.0)
        viewModel.mapView.camera = camera
        searchController.isActive = false
        viewModel.mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchResultsView.isHidden = true
        recentSearchesView.isHidden = true
        filterContainerView.isHidden = false
    }

    func didTapFavoriteButton(for place: Place) {
        // 즐겨찾기 버튼 탭 시 동작 구현
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
            searchResultsView.isHidden = true
        } else {
            recentSearchesView.isHidden = true
            searchResultsView.isHidden = false
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
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            viewModel.currentLocation = location
        }
    }
}

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let place = marker.userData as? Place else {
            return false
        }

        if let navigationController = navigationController {
            let gymDetailVC = GymDetailViewController(place: place)
            navigationController.pushViewController(gymDetailVC, animated: true)
        }

        return true
    }
}

extension MapViewController: FilterViewDelegate {
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: [String]) {
        let query = categories.joined(separator: " ")
        print("선택된 카테고리 쿼리: \(query)")

        placeSearchViewModel.searchPlace(input: query) { [weak self] (places: [Place]) in
            guard let self = self else { return }
            self.viewModel.places.append(contentsOf: places)
            self.viewModel.filterPlaces()
            self.updateClusteringWithSelectedCategories()

            self.viewModel.updateMapMarkers()
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

extension MapViewController: ClusterManagerDelegate {
    func clusterManager(_ clusterManager: ClusterManager, didSelectPlace place: Place) {
        let gymDetailVC = GymDetailViewController(place: place)
        navigationController?.pushViewController(gymDetailVC, animated: true)
    }
}
//extension MapViewController {
//    func mapView(_ mapView: GMSMapView, didFinishTileRendering renderer: GMSTileLayer) {
//        mapView.setMinZoom(4, maxZoom: mapView.maxZoom)
//    }
//
//    // 다른 델리게이트 메서드...
//}
