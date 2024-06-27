//import UIKit
//
//class FavoritesCoordinator: Coordinator {
//    let navigationController: UINavigationController
//    var childCoordinators: [Coordinator] = []
//
//    init(navigationController: UINavigationController) {
//        self.navigationController = navigationController
//    }
//
//    func start() {
//        let viewController = FavoritesViewController()
//        viewController.coordinator = self
//        navigationController.pushViewController(viewController, animated: false)
//    }
//
//    func showPlaceDetails(_ place: Place) {
//        let detailViewController = GymDetailViewController(viewModel: GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: PlaceSearchViewModel()))
//        navigationController.pushViewController(detailViewController, animated: true)
//    }
//}
