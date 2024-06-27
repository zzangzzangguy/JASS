import Foundation

protocol GetFavoritesUseCase {
    func execute(completion: @escaping (Result<[Place], Error>) -> Void)
}

class DefaultGetFavoritesUseCase: GetFavoritesUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    func execute(completion: @escaping (Result<[Place], Error>) -> Void) {
        repository.getFavorites(completion: completion)
    }
}
