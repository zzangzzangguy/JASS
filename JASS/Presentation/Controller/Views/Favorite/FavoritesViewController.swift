import UIKit
import SnapKit
import Toast

class FavoritesViewController: UIViewController {
    weak var coordinator: FavoritesCoordinator?
    var placeSearchViewModel: PlaceSearchViewModel!
    var tableView: UITableView!
    var favoritesManager: FavoritesManager!

    init(viewModel: PlaceSearchViewModel) { // 초기화 인자 추가
           self.placeSearchViewModel = viewModel
           super.init(nibName: nil, bundle: nil)
       }

       required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFavoritesManager()
        setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
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

    private func setupNavigationBar() {
//        navigationController?.navigationBar.barTintColor = .black
//        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = "즐겨찾기"
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
        let viewModel = GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: placeSearchViewModel)
        let gymDetailVC = GymDetailViewController(viewModel: viewModel)
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
