// Presentation/Coordinator/MainCoordinator.swift

import UIKit

class MainCoordinator: Coordinator {
    let tabBarController: UITabBarController
    var childCoordinators: [Coordinator] = []

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    func start() {
        let mainVC = MainViewController()
        mainVC.coordinator = self
        mainVC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        let mapVC = MapViewController(viewModel: PlaceSearchViewModel())
        mapVC.coordinator = self
        mapVC.tabBarItem = UITabBarItem(title: "지도", image: UIImage(systemName: "map"), selectedImage: UIImage(systemName: "map.fill"))

        let favoritesVC = FavoritesViewController()
        favoritesVC.coordinator = self
        favoritesVC.tabBarItem = UITabBarItem(title: "즐겨찾기", image: UIImage(systemName: "heart"), selectedImage: UIImage(systemName: "heart.fill"))

        tabBarController.viewControllers = [
            UINavigationController(rootViewController: mainVC),
            UINavigationController(rootViewController: mapVC),
            UINavigationController(rootViewController: favoritesVC)
        ]
    }

    func showSearchResults(from viewController: UIViewController, for query: String) {
        let searchResultsVC = SearchResultsViewController()
        searchResultsVC.searchQuery = query
        searchResultsVC.placeSearchViewModel = PlaceSearchViewModel()
        searchResultsVC.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: searchResultsVC)
        viewController.navigationController?.pushViewController(searchResultsVC, animated: true)
    }

    func showPlaceDetails(from viewController: UIViewController, for place: Place) {
        let detailViewModel = GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: PlaceSearchViewModel())
        let detailVC = GymDetailViewController(viewModel: detailViewModel)
        viewController.navigationController?.pushViewController(detailVC, animated: true)
    }
}
