import UIKit
import SnapKit
import Toast

class FavoritesViewController: UIViewController {
    var tableView: UITableView!
    var favoritesManager: FavoritesManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFavoritesManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView = UITableView()/*(frame: .zero, style: .plain)*/
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        view.addSubview(tableView)
        tableView.estimatedRowHeight = 120 
        tableView.rowHeight = UITableView.automaticDimension
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.register(FavoritePlaceCell.self, forCellReuseIdentifier: "FavoritePlaceCell")


    }

    private func setupFavoritesManager() {
        favoritesManager = FavoritesManager.shared
    }
}

extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoritesManager.getFavorites().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritePlaceCell", for: indexPath) as! FavoritePlaceCell
        let place = favoritesManager.getFavorites()[indexPath.row]
        cell.configure(with: place)
        cell.delegate = self
        return cell
    }
}

extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = favoritesManager.getFavorites()[indexPath.row]
        let gymDetailVC = GymDetailViewController(place: place)
        navigationController?.pushViewController(gymDetailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension FavoritesViewController: FavoritePlaceCellDelegate {
    func didTapFavoriteButton(for cell: FavoritePlaceCell, isFavorite: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let place = favoritesManager.getFavorites()[indexPath.row]

        if isFavorite {
            favoritesManager.removeFavorite(place: place)
            ToastManager.showToast(message: "즐겨찾기에서 제거되었습니다.", in: self)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } else {
            favoritesManager.addFavorite(place: place)
            ToastManager.showToast(message: "즐겨찾기에 추가되었습니다.", in: self)
            tableView.reloadData()
        }
    }
}
