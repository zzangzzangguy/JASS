import UIKit

protocol CoordinatorDelegate: AnyObject {
    func didFinish(childCoordinator: Coordinator)
}

protocol Coordinator: AnyObject {
    var delegate: CoordinatorDelegate? { get set }
    // var navigationController: UINavigationController { get set }  // 주석 유지
    var childCoordinators: [Coordinator] { get set }
    func start()
    func popViewController()
    func finish()
}

extension Coordinator {
    func finish() {
        childCoordinators.removeAll()
        delegate?.didFinish(childCoordinator: self)
    }

    // 추가: 기본 구현 제공
    func popViewController() {
        // 기본적으로 아무 동작도 하지 않음
    }
}
