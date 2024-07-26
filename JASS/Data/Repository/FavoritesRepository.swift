import Foundation

protocol FavoritesRepository {
    func getFavorites(completion: @escaping (Result<[Place], Error>) -> Void)
}

class DefaultFavoritesRepository: FavoritesRepository {
    func getFavorites(completion: @escaping (Result<[Place], Error>) -> Void) {
        let favorites = FavoritesManager.shared.getFavorites()
        completion(.success(favorites))
    }
}
