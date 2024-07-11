import UIKit
import CoreLocation

final class SearchCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let placeUseCase: PlaceUseCase
    let recentPlacesViewModel: RecentPlacesViewModel

    init(navigationController: UINavigationController, placeUseCase: PlaceUseCase, recentPlacesViewModel: RecentPlacesViewModel) {
        self.navigationController = navigationController
        self.placeUseCase = placeUseCase
        self.recentPlacesViewModel = recentPlacesViewModel
    }

    func start() {
        let viewController = SearchViewController(placeSearchViewModel: PlaceSearchViewModel(placeUseCase: placeUseCase))
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: false)
    }

    func finish() {
        delegate?.didFinish(childCoordinator: self)
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
