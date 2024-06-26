import UIKit
import SnapKit
import Then
import Kingfisher
import CoreLocation
import Toast

protocol SearchResultsViewDelegate: AnyObject {
    func didSelectPlace(_ place: Place)
}

class SearchResultsViewController: UIViewController {

    // MARK: - Properties

    private let searchBar = UISearchBar().then {
        $0.backgroundImage = UIImage()
        $0.placeholder = "검색어를 입력하세요"
    }

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .black
    }

    private let searchButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        $0.tintColor = .black
    }

    private let filterButton = UIButton(type: .system).then {
        $0.setTitle("필터", for: .normal)
        $0.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.tintColor = .black
        $0.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 15
    }

    private lazy var tableView = UITableView().then {
        $0.delegate = self
        $0.dataSource = self
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 120
        $0.keyboardDismissMode = .onDrag
        $0.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseIdentifier)
    }
    var selectedCategories: Set<String> = []
    private let defaultCategory = "헬스,필라테스,크로스핏,복싱,수영,골프,클라이밍"


    var searchQuery: String? {
        didSet {
            searchBar.text = searchQuery
        }
    }
    var placeSearchViewModel: PlaceSearchViewModel?
    var viewModel: SearchResultsViewModel?
    weak var delegate: SearchResultsViewDelegate?
    var mapViewModel: MapViewModel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupActions()
        performInitialSearch()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white
        [backButton, searchBar, searchButton, filterButton, tableView].forEach { view.addSubview($0) }
        setupConstraints()
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.width.height.equalTo(44)
        }

        searchBar.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(8)
            make.trailing.equalTo(searchButton.snp.leading).offset(-8)
            make.centerY.equalTo(backButton)
        }

        searchButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(backButton)
            make.width.height.equalTo(44)
        }

        filterButton.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(30)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterButton.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupBindings() {
        viewModel?.updateSearchResults = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        searchBar.delegate = self
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func searchButtonTapped() {
        performSearch()
    }

    @objc private func filterButtonTapped() {
        let filterVC = FilterViewController()
        filterVC.delegate = self
        filterVC.selectedCategories = selectedCategories  // Set<String>을 그대로 전달
        present(filterVC, animated: true, completion: nil)
    }

    private func performSearch(with categories: [String]? = nil) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        let categoriesToUse = categories ?? Array(selectedCategories)
        let category = categoriesToUse.isEmpty ? "all" : categoriesToUse.joined(separator: ",")

        placeSearchViewModel?.searchPlace(input: query, category: category) { [weak self] places in
            self?.update(with: places)
        }
    }


    private func performInitialSearch() {
        guard let query = searchQuery else { return }
        placeSearchViewModel?.searchPlace(input: query, category: "all") { [weak self] places in
            self?.update(with: places)
        }
    }

    func update(with places: [Place]) {
        print("SearchResultsViewController update with \(places.count) places")
        viewModel?.loadSearchResults(with: places)
        tableView.reloadData()
        if let currentLocation = LocationManager.shared.getCurrentLocation() {
            calculateDistances(for: places, from: currentLocation)
        } else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private func calculateDistances(for places: [Place], from currentLocation: CLLocationCoordinate2D) {
        let group = DispatchGroup()
        for (index, place) in places.enumerated() {
            group.enter()
            placeSearchViewModel?.calculateDistances(from: currentLocation, to: place.coordinate) { [weak self] distance in
                defer { group.leave() }
                guard let self = self else { return }
                var updatedPlace = place
                updatedPlace.distanceText = distance ?? "거리 정보 없음"
                self.viewModel?.updatePlace(updatedPlace)
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
        }
    }
    private func reloadCellForPlace(_ place: Place) {
        guard let indexPath = viewModel?.searchResults.firstIndex(where: { $0.place_id == place.place_id }).map({ IndexPath(row: $0, section: 0) }) else { return }

        DispatchQueue.main.async { [weak self] in
            if let cell = self?.tableView.cellForRow(at: indexPath) as? SearchResultCell {
                cell.distanceLabel.text = place.distanceText ?? "거리 정보 없음"
            }
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension SearchResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.searchResults.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.reuseIdentifier, for: indexPath) as? SearchResultCell,
              let place = viewModel?.searchResults[indexPath.row] else {
            return UITableViewCell()
        }
        
        let currentLocation = LocationManager.shared.getCurrentLocation()
        cell.configure(with: place, currentLocation: currentLocation)
        cell.delegate = self
        
        if let currentLocation = currentLocation {
            placeSearchViewModel?.calculateDistances(from: currentLocation, to: place.coordinate) { [weak self, weak cell] distance in
                DispatchQueue.main.async {
                    cell?.updateDistanceText(distance)
                    if var updatedPlace = self?.viewModel?.searchResults[indexPath.row] {
                        updatedPlace.distanceText = distance
                        self?.viewModel?.updatePlace(updatedPlace)
                    }
                }
            }
        }
        
        placeSearchViewModel?.fetchPlaceDetails(placeID: place.place_id) { [weak cell] detailedPlace in
            DispatchQueue.main.async {
                if let detailedPlace = detailedPlace {
                    cell?.configure(with: detailedPlace, currentLocation: currentLocation)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = viewModel?.searchResults[indexPath.row] else { return }
        //        mapViewModel?.updateSelectedPlaceMarker(for: place)
        
        delegate?.didSelectPlace(place)
        let gymDetailVC = GymDetailViewController(place: place)
        gymDetailVC.modalPresentationStyle = .fullScreen
        present(gymDetailVC, animated: true, completion: nil)
    }
}
// MARK: - SearchResultCellDelegate

extension SearchResultsViewController: SearchResultCellDelegate {
    func didUpdateDistance(for cell: SearchResultCell, distanceText: String?) {
        guard let indexPath = tableView.indexPath(for: cell),
              var place = viewModel?.searchResults[indexPath.row] else { return }

        place.distanceText = distanceText
        reloadCellForPlace(place)
    }

    func didTapFavoriteButton(for cell: SearchResultCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let place = viewModel?.searchResults[indexPath.row] else { return }

        let wasFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id ?? "")
        viewModel?.updateFavoriteStatus(for: place)

        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id ?? "")
        cell.updateFavoriteButton(isFavorite: isFavorite)

        let message = isFavorite ? "즐겨찾기에 추가되었습니다." : "즐겨찾기에서 제거되었습니다."
        view.makeToast(message)
    }
}

// MARK: - UISearchBarDelegate

extension SearchResultsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
}

extension SearchResultsViewController: FilterViewDelegate {
    func filterViewDidCancel(_ filterView: FilterViewController) {
        dismiss(animated: true, completion: nil)

    }
    
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: Set<String>) {
        selectedCategories = categories.isEmpty ? [defaultCategory] : categories

        guard let query = searchBar.text, !query.isEmpty else {
            showToast("검색어를 입력해주세요.")
            return
        }

        performSearch(with: Array(categories))
    }

    private func performSearch(with categories: [String]) {
        LoadingIndicatorManager.shared.show(in: view)

        let category = categories.first ?? defaultCategory
        placeSearchViewModel?.searchPlace(input: searchBar.text ?? "", category: category) { [weak self] places in
            guard let self = self else { return }

            DispatchQueue.main.async {
                LoadingIndicatorManager.shared.hide()

                self.viewModel?.loadSearchResults(with: places)
                self.tableView.reloadData()

                if places.isEmpty {
                    self.showToast("필터링된 장소가 없습니다.")
                }

                if let currentLocation = LocationManager.shared.getCurrentLocation() {
                    self.calculateDistances(for: places, from: currentLocation)
                }
            }
        }
    }

    private func showToast(_ message: String) {
        view.makeToast(message)
    }
}
