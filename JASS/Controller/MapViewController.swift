import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit

class MapViewController: UIViewController, UISearchBarDelegate, SearchResultsViewDelegate, GMSMapViewDelegate {
    // 프로퍼티 선언
    var mapView: GMSMapView!
    var searchController: UISearchController!
    var recentSearchesView: RecentSearchesView!
    var searchResultsView: SearchResultsView!
    var searchTask: DispatchWorkItem?
    var MarkerDebounce: Timer?

    var filterContainerView: UIView!
    var filterStackView: UIStackView!
    var filterButton: UIButton!

    var placeSearchViewModel = PlaceSearchViewModel()
    var searchRecentViewModel = SearchRecentViewModel()

    let zoomInButton = UIButton(type: .system)
    let zoomOutButton = UIButton(type: .system)

    var gymLoader: Gymload! // GymsLoader 인스턴스

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupSearchViews()
        setupSearchController()
        setupZoomButtons()
        setupStatusBarBackground()
        setupFilterButtonView()

        gymLoader = Gymload(mapView: mapView, placeSearchViewModel: placeSearchViewModel) // GymsLoader 초기화

        // 최근 검색 이력 업데이트 콜백 설정
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
            self?.placeSearchViewModel.searchPlace(input: searchText)
            self?.searchResultsView.isHidden = false
            self?.recentSearchesView.isHidden = true
            self?.filterContainerView.isHidden = true
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchRecentViewModel.saveSearchHistory(query: searchText)
            placeSearchViewModel.searchPlace(input: searchText)
        }
    }

    func didSelectPlace(_ place: Place) {
        searchRecentViewModel.saveSearchHistory(query: place.name)
        gymLoader.loadGymsInBounds() // GymsLoader의 loadGymsInBounds() 메서드 호출

        let camera = GMSCameraPosition.camera(withLatitude: place.geometry.location.lat, longitude: place.geometry.location.lng, zoom: 15.0)
        mapView.camera = camera
        searchController.isActive = false
        mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchResultsView.isHidden = true
        recentSearchesView.isHidden = true
        filterContainerView.isHidden = false
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        mapView.isHidden = false
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filterContainerView.isHidden = false
        searchResultsView.isHidden = true
        recentSearchesView.isHidden = true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        mapView.isHidden = true
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

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        MarkerDebounce?.invalidate()
        MarkerDebounce = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.gymLoader.loadGymsInBounds() // GymsLoader의 loadGymsInBounds() 메서드 호출
        }
    }
}
