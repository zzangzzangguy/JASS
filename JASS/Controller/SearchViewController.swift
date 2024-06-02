import UIKit
import SnapKit
import Toast

class SearchViewController: UIViewController {
    private var filterContainerView: UIView!
    private var filterButton: UIButton!
    private var recentSearchesView: RecentSearchesView!
    private var searchResultsView: SearchResultsView!
    private var placeSearchViewModel = PlaceSearchViewModel()
    private var searchRecentViewModel = SearchRecentViewModel()
    private var searchTask: DispatchWorkItem?
    private var selectedCategory: String?
    private let defaultCategory = "헬스"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchViewModels()
        //키보드 이벤트
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupUI() {
        setupFilterButtons()
        setupRecentSearchesView()
        setupSearchResultsView()
    }

    private func setupFilterButtons() {
        filterContainerView = UIView()
        view.addSubview(filterContainerView)
        filterContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
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
        //        filterButton.addTarget(self, action: #selector(showFilterView), for: .touchUpInside)
        filterStackView.addArrangedSubview(filterButton)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardHeight = keyboardFrame.height

        recentSearchesView.snp.updateConstraints {
            $0.bottom.equalToSuperview().inset(keyboardHeight)
        }

        // 애니메이션과 함께 뷰 이동
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        recentSearchesView.snp.updateConstraints {
            $0.bottom.equalToSuperview()
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func setupRecentSearchesView() {
        recentSearchesView = RecentSearchesView()
        recentSearchesView.searchRecentViewModel = searchRecentViewModel
        recentSearchesView.didSelectRecentSearch = { [weak self] query in
            guard let self = self else { return }
            self.searchPlace(query)
        }
        view.addSubview(recentSearchesView)
        recentSearchesView.snp.makeConstraints {
            $0.top.equalTo(filterContainerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        recentSearchesView.isHidden = false
    }

    private func searchPlace(_ query: String) {
        let category = selectedCategory ?? defaultCategory
        print("searchPlace - query: \(query), category: \(category)") // 로그 추가
        placeSearchViewModel.searchPlace(input: query, category: category) { [weak self] places in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.searchResultsView.update(with: places)
                self.searchResultsView.isHidden = false
                self.recentSearchesView.isHidden = true
                self.filterContainerView.isHidden = true
                print("searchPlace - results: \(places)") // 로그 추가
            }
        }
    }

    private func setupSearchResultsView() {
        searchResultsView = SearchResultsView()
        searchResultsView.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: self)
        searchResultsView.placeSearchViewModel = placeSearchViewModel
        //        searchResultsView.delegate = self
        view.addSubview(searchResultsView)
        searchResultsView.snp.makeConstraints {
            $0.top.equalTo(filterContainerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        searchResultsView.isHidden = true
    }

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
            self.searchPlace(query)
        }
    }

    private func showSearchResultsView() {
        recentSearchesView.isHidden = true
        searchResultsView.isHidden = false
        filterContainerView.isHidden = true
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = searchBar.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)

        searchTask?.cancel()
        searchTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let category = self.selectedCategory ?? self.defaultCategory
            print("searchBar - query: \(updatedText), category: \(category)") // 로그 추가
            self.placeSearchViewModel.searchPlace(input: updatedText, category: category) { places in
                DispatchQueue.main.async {
                    self.searchResultsView.update(with: places)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchTask!)

        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchRecentViewModel.saveSearchHistory(query: searchText)
            let category = selectedCategory ?? defaultCategory
            print("searchBarSearchButtonClicked - query: \(searchText), category: \(category)") // 로그 추가
            placeSearchViewModel.searchPlace(input: searchText, category: category) { [weak self] places in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.searchResultsView.update(with: places)
                    self.showSearchResultsView()
                }
            }
        }
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
