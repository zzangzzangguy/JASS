import UIKit
import SnapKit
import GooglePlaces
import CoreLocation

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    var currentLocation: CLLocationCoordinate2D?
    let searchBar = UISearchBar().then {
        $0.placeholder = "지역, 또는 찾고계신 운동을 입력해주세요"
        $0.searchBarStyle = .minimal
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "어떤 운동을 찾고 계신가요?"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    let recommendedKeywords = ["헬스", "요가", "크로스핏", "복싱", "필라테스", "G.X", "주짓수", "골프", "수영"]
    var recentSearches: [String] = []
    var tableView: UITableView!
    var searchRecentViewModel = SearchRecentViewModel()
    var placeSearchViewModel = PlaceSearchViewModel()
    var autoCompleteSuggestions: [String] = []
    var keywordButtons: [UIButton] = []

    let segmentedControl = UISegmentedControl(items: ["추천 검색어", "최근 검색어"])
    let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "일치하는 검색어가 없습니다."
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        return label
    }()

    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecentSearches()
        setupKeywordButtons()
        print("SearchResultsViewController가 로드됨")

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().inset(20)
        }

        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(noResultsLabel)
        noResultsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupKeywordButtons() {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        let containerView = UIView()
        scrollView.addSubview(containerView)

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        let buttonHeight: CGFloat = 32
        let verticalSpacing: CGFloat = 10
        let horizontalSpacing: CGFloat = 8
        let maxWidth = view.frame.width - 40

        for (index, keyword) in recommendedKeywords.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(keyword, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.backgroundColor = .systemGray6
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = buttonHeight / 2
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            button.sizeToFit()
            var buttonWidth = button.frame.width

            buttonWidth = max(buttonWidth, 50)

            if xOffset + buttonWidth + horizontalSpacing > maxWidth {
                xOffset = 0
                yOffset += buttonHeight + verticalSpacing
            }

            button.frame = CGRect(x: xOffset, y: yOffset, width: buttonWidth, height: buttonHeight)
            containerView.addSubview(button)
            keywordButtons.append(button)

            xOffset += buttonWidth + horizontalSpacing
        }

        containerView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView)
            make.height.equalTo(yOffset + buttonHeight)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(containerView.snp.height)
        }

        tableView.snp.remakeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func segmentChanged() {
        updateUIForCurrentState()
    }



    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }

    @objc private func keywordButtonTapped(_ sender: UIButton) {
        guard let keyword = sender.titleLabel?.text else { return }
        searchBar.text = keyword
        performSearch(query: keyword)
    }



    private func loadRecentSearches() {
        recentSearches = searchRecentViewModel.loadRecentSearches()
        tableView.reloadData()
    }
    private func updateUIForCurrentState() {
        let isRecommendedKeywordsSegment = segmentedControl.selectedSegmentIndex == 0
        let isSearching = !(searchBar.text?.isEmpty ?? true)

        tableView.reloadData()

        if isSearching {
            segmentedControl.isHidden = true
            keywordButtons.forEach { $0.isHidden = true }
            tableView.snp.remakeConstraints { make in
                make.top.equalTo(searchBar.snp.bottom).offset(10)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            segmentedControl.isHidden = false
            keywordButtons.forEach { $0.isHidden = !isRecommendedKeywordsSegment }
            if isRecommendedKeywordsSegment {
                tableView.snp.remakeConstraints { make in
                    make.top.equalTo(segmentedControl.snp.bottom).offset(20)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            } else {
                tableView.snp.remakeConstraints { make in
                    make.top.equalTo(segmentedControl.snp.bottom).offset(10)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
        }

        view.layoutIfNeeded()
    }

    private func performSearch(query: String) {
        print("SearchViewController - 현재 위치: \(String(describing: self.currentLocation))")  // 디버그 출력
//        print("검색 실행: \(query)")
        searchRecentViewModel.saveSearchHistory(query: query)
        placeSearchViewModel.searchPlace(input: query, category: "all") { [weak self] places in
            guard let self = self else { return }
            print("API returned \(places.count) places")
            DispatchQueue.main.async {
                let searchResultsVC = SearchResultsViewController()
                searchResultsVC.searchQuery = query
                searchResultsVC.placeSearchViewModel = self.placeSearchViewModel
                searchResultsVC.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: searchResultsVC)
                searchResultsVC.viewModel?.loadSearchResults(with: places)
                searchResultsVC.currentLocation = self.currentLocation
                let navController = UINavigationController(rootViewController: searchResultsVC)
                self.navigationController?.pushViewController(searchResultsVC, animated: true)
                self.navigationController?.setNavigationBarHidden(true, animated: false)

//                searchResultsVC.modalPresentationStyle = .fullScreen
//                self.present(searchResultsVC, animated: true, completion: nil)
            }
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text?.isEmpty == false {
            return autoCompleteSuggestions.count
        } else if segmentedControl.selectedSegmentIndex == 0 {
            return 0
        } else {
            return recentSearches.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if searchBar.text?.isEmpty == false {
            if indexPath.row < autoCompleteSuggestions.count {
                cell.textLabel?.text = autoCompleteSuggestions[indexPath.row]
            }
        } else {
            cell.textLabel?.text = recentSearches[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var keyword: String
        if searchBar.text?.isEmpty == false {
            if indexPath.row < autoCompleteSuggestions.count {
                keyword = autoCompleteSuggestions[indexPath.row]
            } else {
                return
            }
        } else if segmentedControl.selectedSegmentIndex == 0 {
            if indexPath.row < recommendedKeywords.count {
                keyword = recommendedKeywords[indexPath.row]
            } else {
                return
            }
        } else {
            if indexPath.row < recentSearches.count {
                keyword = recentSearches[indexPath.row]
            } else {
                return
            }
        }
        searchBar.text = keyword
        performSearch(query: keyword)
    }

    @objc func deleteRecentSearch(_ sender: UIButton) {
        let index = sender.tag
        searchRecentViewModel.deleteSearchHistory(query: recentSearches[index])
        loadRecentSearches()
        tableView.reloadData()
    }

    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else {
            print("검색어를 입력하세요.")
            return
        }

        LoadingIndicatorManager.shared.show(in: self.view)
        placeSearchViewModel.searchPlace(input: query, category: "all") { [weak self] places in
            guard let self = self else { return }
            print("받은 장소 수: \(places.count)")

            DispatchQueue.main.async {
                LoadingIndicatorManager.shared.hide()

                if places.isEmpty {
                    self.noResultsLabel.isHidden = false
                    self.noResultsLabel.text = "검색 결과가 없습니다."
                } else {
                    self.noResultsLabel.isHidden = true
                    let searchResultsVC = SearchResultsViewController()
                    searchResultsVC.searchQuery = query
                    searchResultsVC.placeSearchViewModel = self.placeSearchViewModel
                    searchResultsVC.currentLocation = self.currentLocation  

                    searchResultsVC.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: searchResultsVC)
                    searchResultsVC.viewModel?.loadSearchResults(with: places)
                    self.navigationController?.pushViewController(searchResultsVC, animated: true)
                    print("검색 결과 표시")
                }
            }
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            autoCompleteSuggestions = []
            updateUIForCurrentState()
        } else {
            placeSearchViewModel.searchAutoComplete(for: searchText) { [weak self] suggestions in
                self?.autoCompleteSuggestions = suggestions
                DispatchQueue.main.async {
                    self?.updateUIForCurrentState()
                }
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }
}
