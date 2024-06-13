import UIKit
import RealmSwift
import SnapKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    let searchBar = UISearchBar().then {
        $0.placeholder = "어떤 운동을 찾고 계신가요?"
        $0.searchBarStyle = .minimal // 줄 없애기
        $0.layer.borderWidth = 1 // 테두리 두께 설정
        $0.layer.borderColor = UIColor.lightGray.cgColor // 테두리 색상 설정
        $0.layer.cornerRadius = 10 // 테두리 모서리 둥글게
        $0.clipsToBounds = true // 서치바 외부 영역 클리핑
    }
    let recommendedKeywords = ["헬스", "요가", "크로스핏", "복싱", "필라테스", "G.X", "주짓수", "골프", "수영"]
    var recentSearches: [String] = []
    var tableView: UITableView!
    var searchRecentViewModel = SearchRecentViewModel()
    var placeSearchViewModel = PlaceSearchViewModel()
    var autoCompleteSuggestions: [String] = []

    let segmentedControl = UISegmentedControl(items: ["추천 검색어", "최근 검색어"])
    let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "일치하는 검색어가 없습니다."
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        return label
    }()

    // 닫기 버튼 추가
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

        // Hide keyboard when table view is scrolled
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }

    private func setupUI() {
        view.backgroundColor = .white

        // 닫기 버튼 추가
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
            make.top.equalTo(searchBar.snp.bottom).offset(20) // 간격 설정
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

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func segmentChanged() {
        tableView.reloadData()
        noResultsLabel.isHidden = true
    }

    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }

    private func loadRecentSearches() {
        recentSearches = searchRecentViewModel.loadRecentSearches()
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text?.isEmpty == false {
            if autoCompleteSuggestions.isEmpty {
                noResultsLabel.isHidden = false
                return 0
            } else {
                noResultsLabel.isHidden = true
                return autoCompleteSuggestions.count
            }
        } else if segmentedControl.selectedSegmentIndex == 0 {
            return recommendedKeywords.count
        } else {
            return recentSearches.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if searchBar.text?.isEmpty == false {
            cell.textLabel?.text = autoCompleteSuggestions[indexPath.row]
        } else if segmentedControl.selectedSegmentIndex == 0 {
            cell.textLabel?.text = recommendedKeywords[indexPath.row]
        } else {
            cell.textLabel?.text = recentSearches[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let keyword: String
        if searchBar.text?.isEmpty == false {
            keyword = autoCompleteSuggestions[indexPath.row]
        } else if segmentedControl.selectedSegmentIndex == 0 {
            keyword = recommendedKeywords[indexPath.row]
        } else {
            keyword = recentSearches[indexPath.row]
        }
        searchBar.text = keyword
        searchBarSearchButtonClicked(searchBar) // 검색어 입력 후 검색 수행
    }

    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchRecentViewModel.saveSearchHistory(query: query)
        let searchResultsVC = SearchResultsViewController()
        searchResultsVC.searchQuery = query // 검색어 전달
        navigationController?.pushViewController(searchResultsVC, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            autoCompleteSuggestions = []
            tableView.reloadData()
            noResultsLabel.isHidden = true
            segmentedControl.isHidden = false // 검색어가 없을 때는 세그먼트컨트롤을 보이게 함
        } else {
            segmentedControl.isHidden = true // 검색어가 입력되면 세그먼트컨트롤을 숨김
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
