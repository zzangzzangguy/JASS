import UIKit
import CoreLocation
import SnapKit
import RxSwift

class MainViewController: UIViewController {
    private let disposeBag = DisposeBag()

    let locationManager = CLLocationManager()
    let searchBar = UISearchBar()
    let findOnMapButton = UIButton()
    let headerView = UIView()
    let tableView = UITableView()
    var currentLocation: CLLocationCoordinate2D?
    var nearbyFacilitiesViewModel: NearbyFacilitiesViewModel!
    var recentPlacesViewModel: RecentPlacesViewModel!
    var viewModel: PlaceSearchViewModel!
    weak var coordinator: MainCoordinator?
    private var hasFetchedInitialLocation = false

    init(viewModel: PlaceSearchViewModel, placeUseCase: PlaceUseCase, recentPlacesViewModel: RecentPlacesViewModel) {
        self.viewModel = viewModel
        self.nearbyFacilitiesViewModel = NearbyFacilitiesViewModel(placeUseCase: placeUseCase)
        self.recentPlacesViewModel = recentPlacesViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupLocationManager()
        setupHeaderView()
        setupSearchBar()
        setupFindOnMapButton()
        setupTableView()
        setupRefreshButton()
        configureNavigationBar()

        nearbyFacilitiesViewModel.reloadData = { [weak self] in
            self?.tableView.reloadData()
            self?.printFetchedPlaces()
        }

        bindRecentPlaces()
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshNearbyFacilities))
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
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(60)
        }
    }

    private func setupSearchBar() {
        searchBar.placeholder = "어떤 운동을 찾고 계신가요?"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupFindOnMapButton() {
        findOnMapButton.setTitle("지도에서 찾기", for: .normal)
        findOnMapButton.setTitleColor(.white, for: .normal)
        findOnMapButton.imageView?.contentMode = .scaleAspectFit
        findOnMapButton.layer.cornerRadius = 10
        findOnMapButton.clipsToBounds = true
        findOnMapButton.layer.cornerRadius = 8
        findOnMapButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        findOnMapButton.setBackgroundImage(UIImage(named: "sungyeop"), for: .normal)
        findOnMapButton.addTarget(self, action: #selector(findOnMapButtonTapped), for: .touchUpInside)
        view.addSubview(findOnMapButton)

        findOnMapButton.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(150)
            $0.height.equalTo(100)
        }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NearbyFacilitiesTableViewCell.self, forCellReuseIdentifier: NearbyFacilitiesTableViewCell.id)
        tableView.register(RecentPlacesTableViewCell.self, forCellReuseIdentifier: RecentPlacesTableViewCell.id)
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(findOnMapButton.snp.bottom).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupRefreshButton() {
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshNearbyFacilities))
        navigationItem.rightBarButtonItem = refreshButton
    }

    @objc func findOnMapButtonTapped() {
        coordinator?.showMap()
    }

    @objc private func refreshNearbyFacilities() {
        guard let location = currentLocation else { return }
        print("refreshNearbyFacilities 호출됨: \(location)")
        nearbyFacilitiesViewModel.fetchNearbyFacilities(at: location) { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()

            self.nearbyFacilitiesViewModel.places.forEach { place in
                group.enter()
                self.viewModel.fetchPlaceDetails(placeID: place.place_id) { detailedPlace in
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
            viewModel.fetchPlaceDetails(placeID: place.place_id) { [weak self] detailedPlace in
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

    private func bindRecentPlaces() {
        recentPlacesViewModel.recentPlacesRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - CLLocationManagerDelegate
extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, !hasFetchedInitialLocation else { return }
        currentLocation = location.coordinate
        print("LocationManager - 현재 위치 업데이트: \(location.coordinate)")
        updateLocationTitle(location: location)
        hasFetchedInitialLocation = true
        locationManager.stopUpdatingLocation()
        fetchNearbyFacilities()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
        self.navigationItem.title = "위치를 가져올 수 없습니다."
    }

    private func updateLocationTitle(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let error = error {
                print("Reverse geocode error: \(error)")
                self.navigationItem.title = "위치를 가져올 수 없습니다."
                return
            }
            if let placemark = placemarks?.first {
                let title = "\(placemark.locality ?? "") \(placemark.subLocality ?? "")"
                DispatchQueue.main.async {
                    self.navigationItem.title = title
                    print("현재 위치: \(title)")
                }
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        coordinator?.showSearch(from: self)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource, FacilityCollectionViewCellDelegate
extension MainViewController: UITableViewDelegate, UITableViewDataSource, FacilityCollectionViewCellDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RecentPlacesTableViewCell.id, for: indexPath)
                    as? RecentPlacesTableViewCell else {
                return UITableViewCell()
            }

            recentPlacesViewModel.recentPlaces
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] places in
                    cell.configure(with: places)
                })
                .disposed(by: disposeBag)

            cell.delegate = self  // 여기에 delegate 설정을 추가합니다.

            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NearbyFacilitiesTableViewCell.id, for: indexPath)
                    as? NearbyFacilitiesTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: nearbyFacilitiesViewModel.places)
            cell.delegate = self
            return cell
        }
    }

    func didTapFacilityCell(_ cell: FacilityCollectionViewCell, place: Place) {
        coordinator?.showPlaceDetails(from: self, for: place)

        if !(cell.superview?.superview is RecentPlacesTableViewCell) {
            recentPlacesViewModel.addRecentPlace(place)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerLabel = UILabel()
        if section == 0 {
            headerLabel.text = "최근 본 운동시설"
        } else {
            headerLabel.text = "내 주변 운동 시설"
        }
        headerLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        headerLabel.textAlignment = .left
        headerLabel.backgroundColor = .white
        return headerLabel
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
}
