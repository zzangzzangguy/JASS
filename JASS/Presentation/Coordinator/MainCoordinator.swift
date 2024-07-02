import UIKit
import CoreLocation

final class MainCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let tabBarController: UITabBarController
    let placeUseCase: PlaceUseCase

    required init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.tabBarController = UITabBarController()
        let placeRepository = PlaceRepositoryImpl(apiService: GooglePlacesAPIService())
        self.placeUseCase = DefaultPlaceUseCase(repository: placeRepository)
    }

    init(navigationController: UINavigationController, tabBarController: UITabBarController, placeUseCase: PlaceUseCase) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
        self.placeUseCase = placeUseCase
    }

    func start() {
        let mainVC = MainViewController(viewModel: PlaceSearchViewModel(placeUseCase: placeUseCase), placeUseCase: placeUseCase)
        mainVC.coordinator = self
        mainVC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        let mainNavController = UINavigationController(rootViewController: mainVC)
        mainNavController.setNavigationBarHidden(false, animated: false)

        let favoritesCoordinator = FavoritesCoordinator(navigationController: UINavigationController(), placeUseCase: placeUseCase)
        childCoordinators.append(favoritesCoordinator)
        favoritesCoordinator.start()
        let favoritesVC = favoritesCoordinator.navigationController.viewControllers.first as! FavoritesViewController
        favoritesVC.tabBarItem = UITabBarItem(title: "즐겨찾기", image: UIImage(systemName: "heart"), selectedImage: UIImage(systemName: "heart.fill"))

        tabBarController.viewControllers = [
            mainNavController,
            favoritesCoordinator.navigationController
        ]
        navigationController.pushViewController(tabBarController, animated: false)
    }

    func showSearch(from viewController: UIViewController) {
        let searchCoordinator = SearchCoordinator(navigationController: UINavigationController(), placeUseCase: placeUseCase)
        childCoordinators.append(searchCoordinator)
        searchCoordinator.start()
        if let searchVC = searchCoordinator.navigationController.viewControllers.first as? SearchViewController {
            searchVC.coordinator = searchCoordinator
            searchCoordinator.navigationController.modalPresentationStyle = .fullScreen
            viewController.present(searchCoordinator.navigationController, animated: true, completion: nil)
        }
    }

    func showPlaceDetails(from viewController: UIViewController, for place: Place) {
        let detailViewModel = GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: PlaceSearchViewModel(placeUseCase: placeUseCase))
        let detailVC = GymDetailViewController(viewModel: detailViewModel)
        detailVC.coordinator = self
        navigationController.pushViewController(detailVC, animated: true)
        navigationController.setNavigationBarHidden(true, animated: true)
    }

    func popViewController() {
        navigationController.popViewController(animated: true)
        navigationController.setNavigationBarHidden(false, animated: true)
    }

    func showMap() {
        let mapCoordinator = MapCoordinator(navigationController: UINavigationController(), placeUseCase: placeUseCase)
        childCoordinators.append(mapCoordinator)
        mapCoordinator.start()
        mapCoordinator.navigationController.modalPresentationStyle = .fullScreen
        tabBarController.present(mapCoordinator.navigationController, animated: true, completion: nil)
    }

    func showSearchResults(from viewController: UIViewController, query: String, places: [Place], currentLocation: CLLocationCoordinate2D?) {
        let searchResultsVC = SearchResultsViewController(placeSearchViewModel: PlaceSearchViewModel(placeUseCase: placeUseCase))
        searchResultsVC.searchQuery = query
        searchResultsVC.currentLocation = currentLocation
        searchResultsVC.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: searchResultsVC)
        searchResultsVC.viewModel?.loadSearchResults(with: places)
        viewController.navigationController?.pushViewController(searchResultsVC, animated: true)
    }
}
