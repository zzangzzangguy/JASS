import UIKit
import CoreLocation

final class MainCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    let tabBarController: UITabBarController
    let placeUseCase: PlaceUseCase
    let recentPlacesViewModel: RecentPlacesViewModel

    var rootViewController: UIViewController {
        return tabBarController
    }

    init(placeUseCase: PlaceUseCase, recentPlaceUseCase: RecentPlaceUseCase) {
        self.tabBarController = UITabBarController()
        self.placeUseCase = placeUseCase
        self.recentPlacesViewModel = RecentPlacesViewModel(recentPlaceUseCase: recentPlaceUseCase)
    }

    func start() {
        let mainVC = MainViewController(viewModel: PlaceSearchViewModel(placeUseCase: placeUseCase), placeUseCase: placeUseCase, recentPlacesViewModel: recentPlacesViewModel)
        mainVC.coordinator = self
        let mainNavController = UINavigationController(rootViewController: mainVC)
        configureNavigationBarAppearance(mainNavController)
        mainNavController.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        let favoritesCoordinator = FavoritesCoordinator(navigationController: UINavigationController(), placeUseCase: placeUseCase)
        childCoordinators.append(favoritesCoordinator)
        favoritesCoordinator.start()
        let favoritesNavController = favoritesCoordinator.navigationController
        configureNavigationBarAppearance(favoritesNavController)
        favoritesNavController.tabBarItem = UITabBarItem(title: "즐겨찾기", image: UIImage(systemName: "heart"), selectedImage: UIImage(systemName: "heart.fill"))

        tabBarController.viewControllers = [mainNavController, favoritesNavController]
    }

    private func configureNavigationBarAppearance(_ navController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.compactAppearance = appearance
    }

    func showSearch(from viewController: UIViewController) {
        let searchCoordinator = SearchCoordinator(navigationController: UINavigationController(), placeUseCase: placeUseCase, recentPlacesViewModel: recentPlacesViewModel)
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
          detailVC.hidesBottomBarWhenPushed = true
          viewController.navigationController?.pushViewController(detailVC, animated: true)
          viewController.navigationController?.setNavigationBarHidden(true, animated: false)
      }


    func popViewController() {
        if let navController = tabBarController.selectedViewController as? UINavigationController {
            navController.popViewController(animated: true)
        }
//        navigationController.setNavigationBarHidden(false, animated: true)
    }

    func showMap() {
        let mapCoordinator = MapCoordinator(navigationController: UINavigationController(), placeUseCase: placeUseCase)
        childCoordinators.append(mapCoordinator)
        mapCoordinator.start()
        mapCoordinator.navigationController.modalPresentationStyle = .fullScreen
        tabBarController.present(mapCoordinator.navigationController, animated: true, completion: nil)
    }

    func showSearchResults(from viewController: UIViewController, query: String, places: [Place], currentLocation: CLLocationCoordinate2D?) {
        let placeSearchViewModel = PlaceSearchViewModel(placeUseCase: placeUseCase)
        let searchResultsViewModel = SearchResultsViewModel(
            favoritesManager: FavoritesManager.shared,
            placeSearchViewModel: placeSearchViewModel,
            recentPlacesViewModel: recentPlacesViewModel
        )
        let searchResultsVC = SearchResultsViewController(
            placeSearchViewModel: placeSearchViewModel,
            recentPlacesViewModel: recentPlacesViewModel,
            viewModel: searchResultsViewModel
        )
        searchResultsVC.searchQuery = query
        searchResultsVC.currentLocation = currentLocation
        searchResultsVC.viewModel?.loadSearchResults(with: places)
        viewController.navigationController?.pushViewController(searchResultsVC, animated: true)
    }
}
