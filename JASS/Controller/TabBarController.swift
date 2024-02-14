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
        
        viewControllers = [homeViewController, mapViewController].map {
            UINavigationController(rootViewController: $0)
        }
    }
}
