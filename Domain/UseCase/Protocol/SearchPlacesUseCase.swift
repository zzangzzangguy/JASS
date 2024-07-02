import Foundation

protocol SearchPlacesUseCase {
    func execute(query: String, completion: @escaping (Result<[Place], Error>) -> Void)
}
