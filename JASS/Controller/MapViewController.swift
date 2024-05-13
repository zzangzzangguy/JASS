import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit
import Toast


class MapViewController: UIViewController, UISearchBarDelegate {
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

    private let loadingIndicator = UIActivityIndicatorView(style: .large) // MapViewController에 추가
    private var filterView: FilterViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStatusBarBackground()
        setupSearchController()
        setupSearchViews()
        setupMapView()
        setupZoomButtons()
        setupFilterButtonView()
        setupLoadingIndicator() // viewDidLoad()에 추가
        viewModel = MapViewModel(mapView: mapView, placeSearchViewModel: placeSearchViewModel)
        clusterManager = ClusterManager(mapView: mapView)
        clusterManager.delegate = self

        setupFilterView()
        setupFilterButton()


        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

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
            let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 15)
            mapView.camera = camera
        }
        let minZoomLevel: Float = 15.0
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
        searchResultsView.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, mapViewController: self)
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
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "지역, 매장명을 검색해주세요"

        navigationItem.searchController = searchController
        self.navigationItem.title = "Search"
        navigationItem.hidesSearchBarWhenScrolling = false
        

        definesPresentationContext = true
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

    private func setupSearchRecentViewModel() {
        searchRecentViewModel.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchController.searchBar.text = query
            self.searchPlace(query)
        }
    }
    private func searchPlace(_ query: String) {
        placeSearchViewModel.searchPlace(input: query) { [weak self] places in
            guard let self = self else { return }
            self.searchResultsView.update(with: places)
            self.showSearchResultsView()
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

        updateZoomButtonsState() // 초기 상태 업데이트
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
        print("searchBarSearchButtonClicked")
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchRecentViewModel.saveSearchHistory(query: searchText)
            if let currentLocation = viewModel.currentLocation {
                placeSearchViewModel.searchPlace(input: searchText) { [weak self] places in
                    guard let self = self else { return }
                    self.viewModel.places = places
                    self.viewModel.filterPlaces()

                    // 검색 결과를 searchResultsView에 업데이트하고 표시
                    self.searchResultsView.update(with: places)
                    self.showSearchResultsView()

                    // 지도에 마커 업데이트
                }
            }
        }
    }
    private func showSearchResultsView() {
        print("showSearchResultsView")
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

//    func didTapFavoriteButton(for place: Place) {
//        print("didTapFavoriteButton")
//
//    }

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
//            searchResultsView.isHidden = true
        } else {
            recentSearchesView.isHidden = true
//            searchResultsView.isHidden = false
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
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
         // 현재 지도의 중심 좌표를 기준으로 반경 내 검색을 실행
         let center = position.target
         let radius = 5000.0 // 5km 반경 내 검색

         // 선택된 카테고리가 있다면 해당 타입을 포함하여 검색
        let types = Array(viewModel.selectedCategories)

         placeSearchViewModel.searchPlacesNearCoordinate(center, radius: radius, types: types) { [weak self] places in
             guard let self = self else { return }

             DispatchQueue.main.async {
                 if places.isEmpty {
                     // 검색 결과가 없으면 토스트 메시지 표시
                     self.view.makeToast("검색 결과가 없습니다. 다른 위치나 조건으로 검색해 보세요.")
                 } else {
                     // 검색 결과가 있으면 내부 모델을 업데이트하고 지도에 마커를 추가
                     self.viewModel.places = places
                     self.viewModel.filterPlaces()
                     self.updateMapMarkers()

//                     self.searchResultsView.update(with: places)
//                     self.showSearchResultsView()
                 }
             }
         }
     }
 }

    extension MapViewController {
        func showToast(_ message: String) {
            view.makeToast(message)
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
extension MapViewController: SearchResultsViewDelegate {

    func showToastForFavorite(place: Place, isAdded: Bool) {
        // 즐겨찾기가 추가되거나 제거됐을 때 표시할 토스트 메시지 구현
        let message = isAdded ? "즐겨찾기에 추가되었습니다." : "즐겨찾기에서 제거되었습니다."
        view.makeToast(message)
    }
}
