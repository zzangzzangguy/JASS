import UIKit

final class AppCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    var tabBarController: UITabBarController

    init(window: UIWindow) {
        self.navigationController = UINavigationController()
        self.tabBarController = UITabBarController()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func start() {
        let placeRepository = PlaceRepositoryImpl(apiService: GooglePlacesAPIService())
        let placeUseCase = DefaultPlaceUseCase(repository: placeRepository)
        let recentPlacesManager = RecentPlacesManager()
        let mainCoordinator = MainCoordinator(navigationController: navigationController, tabBarController: tabBarController, placeUseCase: placeUseCase, recentPlacesManager: recentPlacesManager)
        mainCoordinator.delegate = self
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()
        navigationController.setViewControllers([tabBarController], animated: false)
    }
}

extension AppCoordinator: CoordinatorDelegate {
    func didFinish(childCoordinator: Coordinator) {
        if let index = childCoordinators.firstIndex(where: { $0 === childCoordinator }) {
            childCoordinators.remove(at: index)
        }
    }
}
