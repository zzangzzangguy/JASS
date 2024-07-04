import UIKit
import SnapKit

class RecentSearchesViewController: UIViewController {
    var tableView: UITableView!
    var searchRecentViewModel: SearchRecentViewModel!
    var didSelectRecentSearch: ((String) -> Void)?
    var didDeleteRecentSearch: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.register(RecentSearchCell.self, forCellReuseIdentifier: RecentSearchCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)

        let headerView = createTableHeaderView()
        tableView.tableHeaderView = headerView
    }

    private func createTableHeaderView() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        let headerLabel = UILabel()
        headerLabel.text = "최근 검색어"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 18)
        headerLabel.textColor = UIColor.label
        headerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
        }
        return headerView
    }


    private func findViewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        repeat {
            nextResponder = nextResponder?.next
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
        } while nextResponder != nil
        return nil
    }
}

extension RecentSearchesViewController: UITableViewDelegate, UITableViewDataSource {
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
            let query = recentSearches[indexPath.row]
            self.searchRecentViewModel.deleteSearchHistory(query: query)
//            self.updateSearchHistoryViews()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recentSearches = searchRecentViewModel.loadRecentSearches()
        if !recentSearches.isEmpty {
            let recentSearch = recentSearches[indexPath.row]
            didSelectRecentSearch?(recentSearch)

            if let searchBar = (self.parent as? UISearchController)?.searchBar {
                searchBar.resignFirstResponder()
            } else if let parentVC = self.findViewController(), let searchBar = parentVC.navigationItem.searchController?.searchBar {
                searchBar.resignFirstResponder()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recentSearches = searchRecentViewModel.loadRecentSearches()
            let query = recentSearches[indexPath.row]
            searchRecentViewModel.deleteSearchHistory(query: query)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
