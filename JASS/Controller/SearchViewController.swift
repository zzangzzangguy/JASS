import UIKit
import GoogleMaps
import GooglePlaces
import SnapKit
import Toast

class SearchViewController: UIViewController {
    private var searchBar: UISearchBar!
    private var filterContainerView: UIView!
    private var filterButton: UIButton!
    private var recentSearchesView: RecentSearchesView!
    private var searchResultsView: SearchResultsView!
    //    private var mapView: GMSMapView!
    private var placeSearchViewModel = PlaceSearchViewModel()
    private var searchRecentViewModel = SearchRecentViewModel()
    private var searchTask: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        setupMapView()
        setupSearchViewModels()
        //        mapView.delegate = self
    }

    private func setupUI() {
        setupSearchBar()
        setupFilterButtons()
        setupRecentSearchesView()
        setupSearchResultsView()
    }

    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.backgroundImage = UIImage()
        searchBar.isTranslucent = true
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
        recentSearchesView.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchBar.text = query
            self.placeSearchViewModel.searchPlace(input: query) { places in
                DispatchQueue.main.async {
                    self.searchResultsView.update(with: places)
                    self.showSearchResultsView()
                }
            }
        }
        view.addSubview(recentSearchesView)
        recentSearchesView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        recentSearchesView.isHidden = false
    }

    private func searchPlace(_ query: String) {
        placeSearchViewModel.searchPlace(input: query) { [weak self] places in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.searchResultsView.update(with: places)
                self.searchResultsView.isHidden = false
                self.recentSearchesView.isHidden = true
                //                self.mapView.isHidden = true
                self.filterContainerView.isHidden = true
            }
        }
    }

    private func setupSearchResultsView() {
        searchResultsView = SearchResultsView()
//        searchResultsView.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, searchViewController: self)
        searchResultsView.delegate = self
        view.addSubview(searchResultsView)
        searchResultsView.snp.makeConstraints {
            $0.top.equalTo(filterContainerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        searchResultsView.isHidden = true
    }

    //    private func setupMapView() {
    //        mapView = GMSMapView()
    //        view.addSubview(mapView)
    //        view.sendSubviewToBack(mapView)
    //        mapView.isHidden = true
    //    }
    //
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
        searchRecentViewModel.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchBar.text = query
            self.placeSearchViewModel.searchPlace(input: query) { places in
                DispatchQueue.main.async {
                    self.searchResultsView.update(with: places)
                    self.showSearchResultsView()
                }
            }
        }
    }


    private func showSearchResultsView() {
        recentSearchesView.isHidden = true
        searchResultsView.isHidden = false
        //        mapView.isHidden = true
        filterContainerView.isHidden = true
    }


}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = searchBar.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)

        searchTask?.cancel()
        searchTask = DispatchWorkItem { [weak self] in
            self?.placeSearchViewModel.searchPlace(input: updatedText) { places in
                DispatchQueue.main.async {
                    self?.searchResultsView.update(with: places)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchTask!)

        return true
    }
}

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

extension SearchViewController: SearchResultCellDelegate {
    func didTapFavoriteButton(for cell: SearchResultCell) {
        guard let indexPath = searchResultsView.indexPath(for: cell),
              indexPath.row < placeSearchViewModel.searchResults.count else {
            return
        }

        let place = placeSearchViewModel.searchResults[indexPath.row]
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id)

        if isFavorite {
            FavoritesManager.shared.removeFavorite(place: place)
        } else {
            FavoritesManager.shared.addFavorite(place: place)
        }
    }
}

extension SearchViewController: SearchResultsViewDelegate {
    func didSelectPlace(_ place: Place) {
        let gymDetailVC = GymDetailViewController(place: place)
        navigationController?.pushViewController(gymDetailVC, animated: true)
    }

    func showToastForFavorite(place: Place, isAdded: Bool) {
        ToastManager.showToastForFavorite(place: place, isAdded: isAdded, in: self)
    }
}
