import UIKit

final class AppCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let placeRepository = PlaceRepositoryImpl(apiService: GooglePlacesAPIService())
        let placeUseCase = DefaultPlaceUseCase(repository: placeRepository)
        let recentPlacesManager = RecentPlacesManager()
        let recentPlaceUseCase = DefaultRecentPlaceUseCase(recentPlacesManager: recentPlacesManager)

        let mainCoordinator = MainCoordinator(placeUseCase: placeUseCase, recentPlaceUseCase: recentPlaceUseCase)
        mainCoordinator.delegate = self
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()

        window.rootViewController = mainCoordinator.rootViewController
        window.makeKeyAndVisible()
    }
}

extension AppCoordinator: CoordinatorDelegate {
    func didFinish(childCoordinator: Coordinator) {
        if let index = childCoordinators.firstIndex(where: { $0 === childCoordinator }) {
            childCoordinators.remove(at: index)
        }
    }
}
