import UIKit
import SnapKit
import Then
import Kingfisher

class SearchResultsView: UIView {
    private let tableView = UITableView().then {
        $0.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        $0.rowHeight = 100
    }

    var viewModel: PlaceSearchViewModel?
    weak var delegate: SearchResultsViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
    }

    func update(with places: [Place]) {
        viewModel?.searchResults = places
        tableView.reloadData()
    }
}

extension SearchResultsView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.searchResults.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        if let place = viewModel?.searchResults[indexPath.row] {
            let currentLocation = LocationManager.shared.getCurrentLocation()
            cell.configure(with: place, currentLocation: currentLocation)
            cell.delegate = self
        }
        return cell
    }
}

extension SearchResultsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = viewModel?.searchResults[indexPath.row] else { return }
        delegate?.didSelectPlace(place)
    }
}

extension SearchResultsView: SearchResultCellDelegate {
    func didTapFavoriteButton(for cell: SearchResultCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let place = viewModel?.searchResults[indexPath.row] else { return }

        if FavoritesManager.shared.isFavorite(placeID: place.place_id) {
            FavoritesManager.shared.removeFavorite(placeID: place.place_id)
        } else {
            FavoritesManager.shared.addFavorite(placeID: place.place_id)
        }

        delegate?.didTapFavoriteButton(for: place)
    }
}

protocol SearchResultsViewDelegate: AnyObject {
    func didSelectPlace(_ place: Place)
    func didTapFavoriteButton(for place: Place)
}

protocol SearchResultCellDelegate: AnyObject {
    func didTapFavoriteButton(for cell: SearchResultCell)
}
