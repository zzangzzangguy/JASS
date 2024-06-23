import UIKit
import SnapKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    let searchBar = UISearchBar().then {
        $0.placeholder = "어떤 운동을 찾고 계신가요?"
        $0.searchBarStyle = .minimal
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
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
            make.top.equalTo(segmentedControl.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(noResultsLabel)
        noResultsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupKeywordButtons() {
        let buttonWidth: CGFloat = (view.frame.width - 60) / 3
        let buttonHeight: CGFloat = 40
        let verticalSpacing: CGFloat = 10

        for (index, keyword) in recommendedKeywords.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(keyword, for: .normal)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 20
            button.addTarget(self, action: #selector(keywordButtonTapped(_:)), for: .touchUpInside)

            view.addSubview(button)
            keywordButtons.append(button)

            let row = index / 3
            let column = index % 3

            button.snp.makeConstraints { make in
                make.width.equalTo(buttonWidth)
                make.height.equalTo(buttonHeight)
                make.left.equalTo(view).offset(20 + CGFloat(column) * (buttonWidth + 10))
                make.top.equalTo(segmentedControl.snp.bottom).offset(20 + CGFloat(row) * (buttonHeight + verticalSpacing))
            }
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func segmentChanged() {
        tableView.reloadData()
        keywordButtons.forEach { $0.isHidden = segmentedControl.selectedSegmentIndex != 0 }

        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.snp.updateConstraints { make in
                make.top.equalTo(segmentedControl.snp.bottom).offset(140)
            }
        } else {
            tableView.snp.updateConstraints { make in
                make.top.equalTo(segmentedControl.snp.bottom).offset(10)
            }
        }
        view.layoutIfNeeded()
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
    }

    private func performSearch(query: String) {
        print("검색 실행: \(query)")
        searchRecentViewModel.saveSearchHistory(query: query)

        placeSearchViewModel.searchPlace(input: query, category: "all") { [weak self] places in
            guard let self = self else { return }

            DispatchQueue.main.async {
                let searchResultsVC = SearchResultsViewController()
                searchResultsVC.searchQuery = query
                searchResultsVC.placeSearchViewModel = self.placeSearchViewModel
                searchResultsVC.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: searchResultsVC)
                searchResultsVC.viewModel?.loadSearchResults(with: places)

                searchResultsVC.modalPresentationStyle = .fullScreen
                self.present(searchResultsVC, animated: true, completion: nil)
            }
        }
    }


    // MARK: - UITableViewDataSource & UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentedControl.selectedSegmentIndex == 0 ? 0 : recentSearches.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if searchBar.text?.isEmpty == false {
            if indexPath.row < autoCompleteSuggestions.count {
                cell.textLabel?.text = autoCompleteSuggestions[indexPath.row]
            }
        } else if segmentedControl.selectedSegmentIndex == 0 {
            if indexPath.row < recommendedKeywords.count {
                cell.textLabel?.text = recommendedKeywords[indexPath.row]
            }
        } else {
            if indexPath.row < recentSearches.count {
                cell.textLabel?.text = recentSearches[indexPath.row]
            }
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
    }

    @objc func deleteRecentSearch(_ sender: UIButton) {
        let index = sender.tag
        searchRecentViewModel.deleteSearchHistory(query: recentSearches[index])
        loadRecentSearches()
        tableView.reloadData()
    }

    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        performSearch(query: query)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            autoCompleteSuggestions = []
        print("자동완성:\(autoCompleteSuggestions)")
            tableView.reloadData()
            noResultsLabel.isHidden = true
            segmentedControl.isHidden = false
            keywordButtons.forEach { $0.isHidden = false }
        } else {
            segmentedControl.isHidden = true
            keywordButtons.forEach { $0.isHidden = true }
            placeSearchViewModel.searchAutoComplete(for: searchText) { suggestions in
                self.autoCompleteSuggestions = suggestions
                self.tableView.reloadData()
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }
}
