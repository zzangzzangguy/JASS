//import UIKit
//
//protocol Coordinator: AnyObject {
//    var navigationController: UINavigationController { get set }
//    func start()
//}
//
//class SearchCoordinator: Coordinator {
//    var navigationController: UINavigationController
//
//    init(navigationController: UINavigationController) {
//        self.navigationController = navigationController
//    }
//
//    func start() {
//        let viewController = SearchViewController()
//        viewController.coordinator = self
//        navigationController.pushViewController(viewController, animated: false)
//    }
//
//    func showSearchResults(for query: String, places: [Place]) {
//        let searchResultsVC = SearchResultsViewController()
//        searchResultsVC.searchQuery = query
//        searchResultsVC.placeSearchViewModel = PlaceSearchViewModel()
//        searchResultsVC.viewModel = SearchResultsViewModel(favoritesManager: FavoritesManager.shared, viewController: searchResultsVC)
//        searchResultsVC.viewModel?.loadSearchResults(with: places)
//        navigationController.pushViewController(searchResultsVC, animated: true)
//    }
//}
