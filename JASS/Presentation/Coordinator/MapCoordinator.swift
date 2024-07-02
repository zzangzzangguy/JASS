import UIKit
import GoogleMaps

final class MapCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let placeUseCase: PlaceUseCase

    required init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.placeUseCase = DefaultPlaceUseCase(repository: PlaceRepositoryImpl(apiService: GooglePlacesAPIService())) // 기본값 초기화 추가
    }

    init(navigationController: UINavigationController, placeUseCase: PlaceUseCase) {
        self.navigationController = navigationController
        self.placeUseCase = placeUseCase
    }

    func start() {
        let viewModel = MapViewModel(mapView: GMSMapView(), placeSearchViewModel: PlaceSearchViewModel(placeUseCase: placeUseCase), navigationController: navigationController, coordinator: self)
        let viewController = MapViewController(viewModel: viewModel, coordinator: self)
        viewController.coordinator = self
        navigationController.setViewControllers([viewController], animated: false)

        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissMap))
        viewController.navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func dismissMap() {
        navigationController.dismiss(animated: true, completion: nil)
    }

    func showPlaceDetails(from viewController: UIViewController, for place: Place) {
           let detailViewController = GymDetailViewController(viewModel: GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: PlaceSearchViewModel(placeUseCase: placeUseCase)))
           viewController.navigationController?.pushViewController(detailViewController, animated: true)
       }
   }

