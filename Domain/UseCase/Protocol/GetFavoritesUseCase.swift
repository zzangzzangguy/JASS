import Foundation

protocol GetFavoritesUseCase {
    func execute(completion: @escaping (Result<[Place], Error>) -> Void)
}
