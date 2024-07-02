// Presentation/Coordinator/FavoritesCoordinator.swift
import UIKit

final class FavoritesCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let placeUseCase: PlaceUseCase

    init(navigationController: UINavigationController, placeUseCase: PlaceUseCase) {
        self.navigationController = navigationController
        self.placeUseCase = placeUseCase
    }

    func start() {
        let viewModel = PlaceSearchViewModel(placeUseCase: placeUseCase)
        let viewController = FavoritesViewController(viewModel: viewModel) // viewModel을 초기화 인자로 전달
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: false)
    }

    func showPlaceDetails(_ place: Place) {
        let detailViewController = GymDetailViewController(viewModel: GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: PlaceSearchViewModel(placeUseCase: placeUseCase)))
        navigationController.pushViewController(detailViewController, animated: true)
    }
}
