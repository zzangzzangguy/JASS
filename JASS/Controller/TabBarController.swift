import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        setupViewControllers()
    }

    private func setupViewControllers() {
        let mapViewController = MapViewController()
        mapViewController.tabBarItem = UITabBarItem(
            title: "Map",
            image: UIImage(systemName: "map"),
            selectedImage: UIImage(systemName: "map.fill")
        )

        let homeViewController = MainViewController()
        homeViewController.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        let favoritesViewController = FavoritesViewController()
        favoritesViewController.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
        

        viewControllers = [homeViewController, mapViewController, favoritesViewController].map {
            UINavigationController(rootViewController: $0)
        }
    }
}
