import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, RecentSearchesViewDelegate, SearchResultsViewDelegate {
    // 프로퍼티 선언
    var searchBar: UISearchBar!
    var filterContainerView: UIView!
     var filterStackView: UIStackView!
     var filterButton: UIButton!

    var recentSearchesView: RecentSearchesView!
    var searchResultsView: SearchResultsView!
    var mapView: GMSMapView!




    var placeSearchViewModel = PlaceSearchViewModel()
    var searchRecentViewModel = SearchRecentViewModel()
    private var searchTask: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupSearchViewModels()
    }

    private func setupUI() {
        setupSearchBar()
        setupFilterButtons()

        setupRecentSearchesView()
        setupSearchResultsView()
    }
    private func setupFilterButtons() {
          filterContainerView = UIView()
          filterStackView = UIStackView()
          filterButton = UIButton(type: .system)

          view.addSubview(filterContainerView)
          filterContainerView.snp.makeConstraints {
              $0.top.equalTo(searchBar.snp.bottom)
              $0.leading.trailing.equalToSuperview()
              $0.height.equalTo(50) // 높이 설정
          }

          filterStackView.axis = .horizontal
          filterStackView.distribution = .fillEqually
          filterStackView.spacing = 10
          filterContainerView.addSubview(filterStackView)
          filterStackView.snp.makeConstraints {
              $0.edges.equalToSuperview().inset(10)
          }

          filterButton.setTitle("카테고리 필터", for: .normal)
          filterButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
//          filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        filterContainerView.isHidden = false
          filterStackView.addArrangedSubview(filterButton)
      }

    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
        }
    }

    private func setupRecentSearchesView() {
        recentSearchesView = RecentSearchesView()
        recentSearchesView.searchRecentViewModel = searchRecentViewModel
        recentSearchesView.delegate = self
        view.addSubview(recentSearchesView)
        recentSearchesView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        recentSearchesView.isHidden = true
    }

    private func setupSearchResultsView() {
        searchResultsView = SearchResultsView()
        searchResultsView.tableView.delegate = self
        searchResultsView.tableView.dataSource = self
        searchResultsView.viewModel = placeSearchViewModel
        searchResultsView.delegate = self
        view.addSubview(searchResultsView)
        searchResultsView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        searchResultsView.isHidden = true
    }

    private func setupMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        mapView.isHidden = true
    }

    private func setupSearchViewModels() {
        placeSearchViewModel.updateSearchResults = { [weak self] in
            DispatchQueue.main.async {
                self?.searchResultsView.tableView.reloadData()
                self?.searchResultsView.isHidden = false
                self?.recentSearchesView.isHidden = true
                self?.mapView.isHidden = true
            }
        }

        searchRecentViewModel.updateRecentSearches = { [weak self] in
            DispatchQueue.main.async {
                self?.recentSearchesView.updateSearchHistoryViews()
            }
        }
    }

    // UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource 구현
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.placeSearchViewModel.searchPlace(input: searchText)
        }
        self.searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeSearchViewModel.searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsCell", for: indexPath) as? SearchResultsCell else {
            return UITableViewCell()
        }
        cell.configure(with: placeSearchViewModel.searchResults[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlace = placeSearchViewModel.searchResults[indexPath.row]
        searchRecentViewModel.saveSearchHistory(query: selectedPlace.name)

        mapView.addCustomMarker(at: selectedPlace.geometry.location, title: selectedPlace.name)
        mapView.animateToLocation(selectedPlace.geometry.location)

        mapView.isHidden = false
        recentSearchesView.isHidden = true
        searchResultsView.isHidden = true
    }

    // RecentSearchesViewDelegate 및 SearchResultsViewDelegate 메서드
    func didSelectPlace(_ place: Place) {
        mapView.addCustomMarker(at: place.geometry.location, title: place.name)
        mapView.animateToLocation(place.geometry.location)

        mapView.isHidden = false
        searchResultsView.isHidden = true
    }

    func didSelectRecentSearch(query: String) {
        searchBar.text = query
        placeSearchViewModel.searchPlace(input: query)
        searchResultsView.isHidden = false
        recentSearchesView.isHidden = true
        mapView.isHidden = true
    }

    func didDeleteRecentSearch(query: String) {
        searchRecentViewModel.deleteSearchHistory(query: query)
    }
}
