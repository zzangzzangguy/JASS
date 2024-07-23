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
        searchResultsVC.coordinator = self
        searchResultsVC.searchQuery = query
        searchResultsVC.currentLocation = currentLocation
        searchResultsVC.viewModel?.loadSearchResults(with: places)
        navigationController.pushViewController(searchResultsVC, animated: true)
    }

    func showPlaceDetails(from viewController: UIViewController, for place: Place) {
        let detailViewModel = GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: PlaceSearchViewModel(placeUseCase: placeUseCase))
        let detailVC = GymDetailViewController(viewModel: detailViewModel)
        detailVC.coordinator = self  
        detailVC.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(detailVC, animated: true)
        navigationController.setNavigationBarHidden(true, animated: false)
    }

    func dismiss() {
        navigationController.dismiss(animated: true, completion: nil)
    }
    
    func popViewController() {
          navigationController.popViewController(animated: true)
      }
}
