import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit

class SearchViewController: UIViewController {
    // MARK: - Properties
    private var searchBar: UISearchBar!
    private var filterContainerView: UIView!
    private var filterButton: UIButton!

    private var recentSearchesView: RecentSearchesView!
    private var searchResultsView: SearchResultsView!
    private var mapView: GMSMapView!

    private var placeSearchViewModel = PlaceSearchViewModel()
    private var searchRecentViewModel = SearchRecentViewModel()
    private var searchTask: DispatchWorkItem?

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupSearchViewModels()

        mapView.delegate = self
    }

    // MARK: - UI Setup
    private func setupUI() {
        setupSearchBar()
        setupFilterButtons()
        setupRecentSearchesView()
        setupSearchResultsView()
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

    private func setupFilterButtons() {
        filterContainerView = UIView()
        view.addSubview(filterContainerView)
        filterContainerView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(50)
        }

        let filterStackView = UIStackView()
        filterStackView.axis = .horizontal
        filterStackView.distribution = .fillEqually
        filterStackView.spacing = 10
        filterContainerView.addSubview(filterStackView)
        filterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(10)
        }

        filterButton = UIButton(type: .system)
        filterButton.setTitle("카테고리 필터", for: .normal)
        filterButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        filterContainerView.isHidden = false
        filterStackView.addArrangedSubview(filterButton)
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
//        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
//        mapView = GMSMapView(frame: view.bounds)
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        mapView.isHidden = true
    }

    // MARK: - Search View Models
    private func setupSearchViewModels() {
        setupPlaceSearchViewModel()
        setupSearchRecentViewModel()
    }

    private func setupPlaceSearchViewModel() {
        placeSearchViewModel.updateSearchResults = { [weak self] in
            DispatchQueue.main.async {
                self?.searchResultsView.update(with: self?.placeSearchViewModel.searchResults ?? [])
                self?.showSearchResultsView()
            }
        }
    }

    private func setupSearchRecentViewModel() {
        searchRecentViewModel.updateRecentSearches = { [weak self] in
            DispatchQueue.main.async {
                self?.recentSearchesView.updateSearchHistoryViews()
            }
        }
    }

    // MARK: - Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.placeSearchViewModel.searchPlace(input: searchText) { places in
                DispatchQueue.main.async {
                    self?.searchResultsView.update(with: places)
                }
            }
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    // MARK: - RecentSearchesViewDelegate & SearchResultsViewDelegate
    func didSelectPlace(_ place: Place) {
        showMapViewWithPlace(place)
    }

    func didTapFavoriteButton(for place: Place) {
        // 즐겨찾기 버튼 탭 시 동작 구현
    }

    func didSelectRecentSearch(query: String) {
        searchBar.text = query
        placeSearchViewModel.searchPlace(input: query) { [weak self] places in
            DispatchQueue.main.async {
                self?.searchResultsView.update(with: places)
                self?.showSearchResultsView()
            }
        }
    }

    func didDeleteRecentSearch(query: String) {
        searchRecentViewModel.deleteSearchHistory(query: query)
    }

    // MARK: - Helper Methods
    private func showSearchResultsView() {
        recentSearchesView.isHidden = true
        searchResultsView.isHidden = false
        mapView.isHidden = true
    }

    private func showMapViewWithPlace(_ place: Place) {
        mapView.addCustomMarker(at: place.coordinate, title: place.name)
        mapView.animateToLocation(place.coordinate)

        recentSearchesView.isHidden = true
        searchResultsView.isHidden = true
        mapView.isHidden = false
    }
}

// MARK: - Extensions
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = searchBar.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)

        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.placeSearchViewModel.searchPlace(input: updatedText) { places in
                DispatchQueue.main.async {
                    self?.searchResultsView.update(with: places)
                }
            }
        }

        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)

        return true
    }
}

extension SearchViewController: RecentSearchesViewDelegate {}
extension SearchViewController: SearchResultsViewDelegate {}
extension SearchViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let place = marker.userData as? Place else {
            return false
        }

        let gymDetailVC = GymDetailViewController(place: place)
        navigationController?.pushViewController(gymDetailVC, animated: true)

        return true
    }
}
