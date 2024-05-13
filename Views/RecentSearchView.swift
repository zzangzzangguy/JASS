import UIKit
import SnapKit

class RecentSearchesView: UIView, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView!
    var searchRecentViewModel: SearchRecentViewModel!

    var didSelectRecentSearch: ((String) -> Void)?
    var didDeleteRecentSearch: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.register(RecentSearchCell.self, forCellReuseIdentifier: RecentSearchCell.reuseIdentifier)
    }

    func updateSearchHistoryViews() {
        let recentSearches = searchRecentViewModel.loadRecentSearches()
        tableView.reloadData()
        if recentSearches.isEmpty {
            let noDataLabel = UILabel()
            noDataLabel.text = "최근 검색어가 없습니다."
            noDataLabel.textAlignment = .center
            noDataLabel.textColor = .gray
            tableView.backgroundView = noDataLabel
            tableView.allowsSelection = false
        } else {
            tableView.backgroundView = nil
            tableView.allowsSelection = true
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchRecentViewModel.loadRecentSearches().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let recentSearches = searchRecentViewModel.loadRecentSearches()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecentSearchCell.reuseIdentifier, for: indexPath) as? RecentSearchCell else {
            return UITableViewCell()
        }
        cell.configure(with: recentSearches[indexPath.row])
        cell.deleteButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.didDeleteRecentSearch?(recentSearches[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recentSearches = searchRecentViewModel.loadRecentSearches()
        if !recentSearches.isEmpty {
            let recentSearch = recentSearches[indexPath.row]
            didSelectRecentSearch?(recentSearch)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recentSearches = searchRecentViewModel.loadRecentSearches()
            let query = recentSearches[indexPath.row]
            searchRecentViewModel.deleteSearchHistory(query: query)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let headerLabel = UILabel()
        headerLabel.text = "최근 검색어"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 18)
        headerLabel.textColor = .black
        headerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
