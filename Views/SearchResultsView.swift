import UIKit
import SnapKit
import Then
import Kingfisher
import CoreLocation

class SearchResultsView: UIView {
    private let tableView = UITableView().then {
        $0.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        $0.rowHeight = 100
    }

    var placeSearchViewModel: PlaceSearchViewModel?
    var viewModel: SearchResultsViewModel?
    weak var delegate: SearchResultsViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBindings()
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

    private func setupBindings() {
        viewModel?.updateSearchResults = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    func update(with places: [Place]) {
        viewModel?.loadSearchResults(with: places)
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
            cell.placeSearchViewModel = placeSearchViewModel
            cell.configure(with: place, currentLocation: currentLocation)
            cell.delegate = self

            if let currentLocation = currentLocation {
                placeSearchViewModel?.calculateDistances(from: currentLocation, to: place.coordinate) { [weak cell] distance in
                    DispatchQueue.main.async {
                        cell?.distanceLabel.text = distance ?? "거리 정보 없음"
                        print("거리 정보 업데이트: \(distance ?? "거리 정보 없음")")
                    }
                }
            }
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
                          let place = viewModel?.searchResults[indexPath.row] else {
                        return
                    }

                    let isFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id)
                    viewModel?.updateFavoriteStatus(for: place)

                    cell.updateFavoriteButton(isFavorite: !isFavorite)

                    delegate?.showToastForFavorite(place: place, isAdded: !isFavorite)
                }
            }

            protocol SearchResultsViewDelegate: AnyObject {
                func didSelectPlace(_ place: Place)
                func showToastForFavorite(place: Place, isAdded: Bool)
            }

            extension SearchResultsView {
                func indexPath(for cell: UITableViewCell) -> IndexPath? {
                    return tableView.indexPath(for: cell)
                }

                func reloadRowAtIndexPath(_ indexPath: IndexPath) {
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
