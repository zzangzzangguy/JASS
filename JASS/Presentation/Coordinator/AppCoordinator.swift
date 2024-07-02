import UIKit

final class AppCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showMainViewController()
    }

    private func showMainViewController() {
        let tabBarController = UITabBarController()
        let placeRepository = PlaceRepositoryImpl(apiService: GooglePlacesAPIService())
        let placeUseCase = DefaultPlaceUseCase(repository: placeRepository) 
        let mainCoordinator = MainCoordinator(navigationController: navigationController, tabBarController: tabBarController, placeUseCase: placeUseCase)
        mainCoordinator.delegate = self
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()

        navigationController.setViewControllers([tabBarController], animated: false)
//        navigationController.setNavigationBarHidden(true, animated: false)
    }
}

extension AppCoordinator: CoordinatorDelegate {
    func didFinish(childCoordinator: Coordinator) {
        if let index = childCoordinators.firstIndex(where: { $0 === childCoordinator }) {
            childCoordinators.remove(at: index)
        }
    }
}
