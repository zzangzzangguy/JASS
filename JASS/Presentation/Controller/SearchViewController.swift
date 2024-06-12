import UIKit
import RealmSwift

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    let searchBar = UISearchBar().then {
        $0.placeholder = "어떤 운동을 찾고 계신가요?"
    }
    let recommendedKeywords = ["헬스", "요가", "크로스핏", "복싱", "필라테스", "G.X", "주짓수", "골프", "수영"]
    var recentSearches: [String] = []
    var tableView: UITableView!
    var searchRecentViewModel = SearchRecentViewModel()

    let segmentedControl = UISegmentedControl(items: ["추천 검색어", "최근 검색어"])

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecentSearches()
    }

    private func setupUI() {
        view.backgroundColor = .white

        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(10)
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
    }

    @objc private func segmentChanged() {
        tableView.reloadData()
    }

    private func loadRecentSearches() {
        recentSearches = searchRecentViewModel.loadRecentSearches()
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return recommendedKeywords.count
        } else {
            return recentSearches.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.textLabel?.text = recommendedKeywords[indexPath.row]
        } else {
            cell.textLabel?.text = recentSearches[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let keyword: String
        if segmentedControl.selectedSegmentIndex == 0 {
            keyword = recommendedKeywords[indexPath.row]
        } else {
            keyword = recentSearches[indexPath.row]
        }
        searchBar.text = keyword
        searchBarSearchButtonClicked(searchBar)
    }

    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchRecentViewModel.saveSearchHistory(query: query)
        let searchResultsVC = SearchResultsViewController()
        searchResultsVC.searchQuery = query // 검색어 전달
        navigationController?.pushViewController(searchResultsVC, animated: true)
    }
}
