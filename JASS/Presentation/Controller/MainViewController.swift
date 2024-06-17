import UIKit
import CoreLocation
import SnapKit

class MainViewController: UIViewController {
    let locationManager = CLLocationManager()
    let searchBar = UISearchBar()
    let currentLocationLabel = UILabel()
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

        headerView.addSubview(currentLocationLabel)
        currentLocationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
    }

    private func setupSearchBar() {
        searchBar.placeholder = "어떤 운동을 찾고 계신가요?"
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupFindOnMapButton() {
        findOnMapButton.setTitle("지도에서 찾기", for: .normal)
        findOnMapButton.backgroundColor = .systemBlue
        findOnMapButton.setTitleColor(.white, for: .normal)
        findOnMapButton.layer.cornerRadius = 8
        findOnMapButton.addTarget(self, action: #selector(findOnMapButtonTapped), for: .touchUpInside)
        view.addSubview(findOnMapButton)
        findOnMapButton.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
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
        nearbyFacilitiesViewModel.refreshRandomPlaces()
    }

    private func fetchNearbyFacilities() {
        guard let location = currentLocation else { return }
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
                self.currentLocationLabel.text = "위치를 가져올 수 없습니다."
                return
            }
            if let placemark = placemarks?.first {
                self.currentLocationLabel.text = "\(placemark.locality ?? "") \(placemark.subLocality ?? "")"
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
        searchVC.modalPresentationStyle = .overFullScreen
        self.present(searchVC, animated: true) {
            searchVC.searchBar.becomeFirstResponder()
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
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
        return cell
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
