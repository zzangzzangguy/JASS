import Foundation

class DefaultGetFavoritesUseCase: GetFavoritesUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    func execute(completion: @escaping (Result<[Place], Error>) -> Void) {
        repository.getFavorites { result in
            switch result {
            case .success(let favorites):
                completion(.success(favorites))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
