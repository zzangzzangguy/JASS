import UIKit
import SnapKit
import Then
import Kingfisher
import CoreLocation

class SearchResultsViewController: UIViewController {
    var searchQuery: String?
    var tableView: UITableView!
    var placeSearchViewModel: PlaceSearchViewModel?
    var viewModel: SearchResultsViewModel?
    weak var delegate: SearchResultsViewDelegate?
    var mapViewModel: MapViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
//        print("PlaceSearchViewModel 생성")
        placeSearchViewModel = PlaceSearchViewModel()
        

    }

    private func setupUI() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 120
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        view.addSubview(tableView)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.keyboardDismissMode = .onDrag
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

extension SearchResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.searchResults.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell

        if let place = viewModel?.searchResults[indexPath.row] {
            let currentLocation = LocationManager.shared.getCurrentLocation()
            cell.placeSearchViewModel = placeSearchViewModel
            cell.configure(with: place, currentLocation: currentLocation)
            cell.distanceLabel.text = place.distanceText ?? "거리 정보 없음"

            cell.delegate = self

            print("Fetching details for place: \(place.place_id)")

            placeSearchViewModel?.fetchPlaceDetails(placeID: place.place_id) { [weak cell] detailedPlace in
                if let detailedPlace = detailedPlace {
                    DispatchQueue.main.async {
                        cell?.configure(with: detailedPlace, currentLocation: currentLocation)
                    }
                } else {
                    print("detailedPlace가 nil입니다.")
                }
            }

            if let currentLocation = currentLocation {
                placeSearchViewModel?.calculateDistances(from: currentLocation, to: place.coordinate) { [weak self, weak cell] distance in
                    DispatchQueue.main.async {
                        cell?.updateDistanceText(distance)
                        print("거리 정보 업데이트: \(distance ?? "거리 정보 없음")")

                        if let place = self?.viewModel?.searchResults[indexPath.row] {
                            self?.reloadCellForPlace(place)
                        }
                    }
                }
            } else {
                print("위치 정보가 충분하지 않습니다.")
            }
        }

        return cell
    }
    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = viewModel?.searchResults[indexPath.row] else { return }
        guard let selectedPlace = viewModel?.searchResults[indexPath.row] else {
            print("선택한 장소가 검색 결과 목록에 없습니다.")
            return
        }

        mapViewModel?.updateSelectedPlaceMarker(for: selectedPlace)
        delegate?.didSelectPlace(place)
    }
    
    func reloadCellForPlace(_ place: Place) {
        guard let indexPath = viewModel?.searchResults.firstIndex(where: { $0.place_id == place.place_id }) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let cell = self.tableView.cellForRow(at: IndexPath(row: indexPath, section: 0)) as? SearchResultCell {
                cell.distanceLabel.text = place.distanceText ?? "거리 정보 없음"
            }

            self.tableView.reloadRows(at: [IndexPath(row: indexPath, section: 0)], with: .automatic)
        }
    }
}


extension SearchResultsViewController: SearchResultCellDelegate {

    func didUpdateDistance(for cell: SearchResultCell, distanceText: String?) {
        guard let indexPath = tableView.indexPath(for: cell),
              var place = viewModel?.searchResults[indexPath.row] else {
            return
        }

        place.distanceText = distanceText
        reloadCellForPlace(place)
    }

    func didTapFavoriteButton(for cell: SearchResultCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let place = viewModel?.searchResults[indexPath.row] else {
            return
        }

        viewModel?.updateFavoriteStatus(for: place)

        cell.updateFavoriteButton(isFavorite: !FavoritesManager.shared.isFavorite(placeID: place.place_id ?? ""))
        delegate?.showToastForFavorite(place: place, isAdded: !FavoritesManager.shared.isFavorite(placeID: place.place_id ?? ""))
    }
}

protocol SearchResultsViewDelegate: AnyObject {
    func didSelectPlace(_ place: Place)
    func showToastForFavorite(place: Place, isAdded: Bool)
}

extension SearchResultsViewController {
    func indexPath(for cell: UITableViewCell) -> IndexPath? {
        return tableView.indexPath(for: cell)
    }

}
