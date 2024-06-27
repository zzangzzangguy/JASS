import UIKit
import CoreLocation
import SnapKit

class MainViewController: UIViewController {
    let locationManager = CLLocationManager()
    let searchBar = UISearchBar()
    let findOnMapButton = UIButton()
    let headerView = UIView()
    let tableView = UITableView()
    var currentLocation: CLLocationCoordinate2D?
    let nearbyFacilitiesViewModel = NearbyFacilitiesViewModel()
    let placeSearchViewModel = PlaceSearchViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupLocationManager()
        setupHeaderView()
        setupSearchBar()
        setupFindOnMapButton()
        setupTableView()
        setupRefreshButton()

//        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

        nearbyFacilitiesViewModel.reloadData = { [weak self] in
            self?.tableView.reloadData()
            self?.printFetchedPlaces()
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func setupHeaderView() {
        headerView.backgroundColor = .white
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
    }

    private func setupSearchBar() {
        searchBar.placeholder = "어떤 운동을 찾고 계신가요?"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupFindOnMapButton() {
        findOnMapButton.setTitle("지도에서 찾기", for: .normal)
        findOnMapButton.setTitleColor(UIColor.white, for: .normal)
        findOnMapButton.imageView?.contentMode = .scaleAspectFit
        findOnMapButton.layer.cornerRadius = 10
        findOnMapButton.clipsToBounds = true
        findOnMapButton.layer.cornerRadius = 8
        findOnMapButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        findOnMapButton.setBackgroundImage(UIImage(named: "sungyeop"), for: .normal)
        findOnMapButton.addTarget(self, action: #selector(findOnMapButtonTapped), for: .touchUpInside)
        view.addSubview(findOnMapButton)
        findOnMapButton.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(20)
                  make.centerX.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(100)
        }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NearbyFacilitiesTableViewCell.self, forCellReuseIdentifier: NearbyFacilitiesTableViewCell.id)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(findOnMapButton.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupRefreshButton() {
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshNearbyFacilities))
        navigationItem.rightBarButtonItem = refreshButton
    }

    @objc func findOnMapButtonTapped() {
        let mapVC = MapViewController(viewModel: placeSearchViewModel)
        self.navigationController?.pushViewController(mapVC, animated: true)
    }

    @objc private func refreshNearbyFacilities() {
        guard let location = currentLocation else { return }
        print("refreshNearbyFacilities 호출됨: \(location)")
        nearbyFacilitiesViewModel.fetchNearbyFacilities(at: location) { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()

            self.nearbyFacilitiesViewModel.places.forEach { place in
                group.enter()
                self.placeSearchViewModel.fetchPlaceDetails(placeID: place.place_id) { detailedPlace in
                    if let detailedPlace = detailedPlace {
                        if let index = self.nearbyFacilitiesViewModel.places.firstIndex(where: { $0.place_id == place.place_id }) {
                            self.nearbyFacilitiesViewModel.places[index] = detailedPlace
                        }
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.tableView.reloadData()
            }
        }
    }

    private func fetchNearbyFacilities() {
        guard let location = currentLocation else { return }
        print("fetchNearbyFacilities 호출됨: \(location)")

        nearbyFacilitiesViewModel.fetchNearbyFacilities(at: location) { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

            self.loadDetailedPlaceInformation()
        }
    }

    private func loadDetailedPlaceInformation() {
        let group = DispatchGroup()

        for (index, place) in nearbyFacilitiesViewModel.places.enumerated() {
            group.enter()
            placeSearchViewModel.fetchPlaceDetails(placeID: place.place_id) { [weak self] detailedPlace in
                defer { group.leave() }
                guard let self = self, let detailedPlace = detailedPlace else { return }

                DispatchQueue.main.async {
                    self.nearbyFacilitiesViewModel.places[index] = detailedPlace
                    if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(IndexPath(row: index, section: 0)) {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            print("모든 상세 정보 로딩 완료")
        }
    }

    private func printFetchedPlaces() {
        print("Fetched Places in MainViewController: \(nearbyFacilitiesViewModel.places.map { "\($0.name): \($0.formatted_address ?? "주소 없음")" })")
    }
}

// MARK: - CLLocationManagerDelegate
extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let error = error {
                print("Reverse geocode error: \(error)")
                self.navigationItem.title = "위치를 가져올 수 없습니다."
                return
            }
            if let placemark = placemarks?.first {
                self.navigationItem.title = "\(placemark.locality ?? "") \(placemark.subLocality ?? "")"
            }
        }
        locationManager.stopUpdatingLocation()
        fetchNearbyFacilities()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let searchVC = SearchViewController()
        searchVC.currentLocation = self.currentLocation  // 현재 위치 전달

        let navController = UINavigationController(rootViewController: searchVC)
        navController.modalPresentationStyle = .overFullScreen
        self.present(navController, animated: true) {
            searchVC.searchBar.becomeFirstResponder()
        }
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource, FacilityCollectionViewCellDelegate
extension MainViewController: UITableViewDelegate, UITableViewDataSource, FacilityCollectionViewCellDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NearbyFacilitiesTableViewCell.id, for: indexPath) as? NearbyFacilitiesTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: nearbyFacilitiesViewModel.places)
        cell.delegate = self
        return cell
    }

    func didTapFacilityCell(_ cell: FacilityCollectionViewCell, place: Place) {
        let gymDetailViewModel = GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: placeSearchViewModel)
        let gymDetailVC = GymDetailViewController(viewModel: gymDetailViewModel)
        navigationController?.pushViewController(gymDetailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerLabel = UILabel()
        headerLabel.text = "내 주변 운동 시설"
        headerLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        headerLabel.textAlignment = .left
        headerLabel.backgroundColor = .white
        return headerLabel
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
}
 
