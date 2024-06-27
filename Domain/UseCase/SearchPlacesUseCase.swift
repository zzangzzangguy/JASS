import Foundation

protocol SearchPlacesUseCase {
    func execute(query: String, completion: @escaping (Result<[Place], Error>) -> Void)
}

class DefaultSearchPlacesUseCase: SearchPlacesUseCase {
    private let repository: PlaceRepository

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func execute(query: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        repository.searchPlaces(query: query, completion: completion)
    }
}
