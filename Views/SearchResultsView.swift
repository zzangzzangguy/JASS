// SearchResultsView.swift
import UIKit
import SnapKit

protocol SearchResultsViewDelegate: AnyObject {
    func didSelectPlace(_ place: Place)
}

class SearchResultsView: UIView, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView!
    weak var viewModel: PlaceSearchViewModel? {
        didSet {
            viewModel?.updateSearchResults = { [weak self] in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    weak var delegate: SearchResultsViewDelegate?

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
        addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.register(SearchResultsCell.self, forCellReuseIdentifier: SearchResultsCell.reuseIdentifier)
    }

    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 옵셔널 바인딩을 사용하여 viewModel의 searchResults가 유효한지 확인
        guard let count = viewModel?.searchResults.count else {
            // viewModel이 nil이거나 searchResults가 없는 경우
            return 0
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultsCell.reuseIdentifier, for: indexPath) as? SearchResultsCell,
              let place = viewModel?.searchResults[indexPath.row] else {
            return UITableViewCell()
        }
        cell.configure(with: place)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = viewModel?.searchResults[indexPath.row] else { return }
        delegate?.didSelectPlace(place)
    }
}
