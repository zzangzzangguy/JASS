// Application/AppCoordinator.swift

import UIKit

class AppCoordinator: Coordinator {
    let window: UIWindow
    var childCoordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let tabBarController = UITabBarController()
        let mainCoordinator = MainCoordinator(tabBarController: tabBarController)
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}
