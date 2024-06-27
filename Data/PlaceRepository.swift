import Foundation

protocol PlaceRepository {
    func searchPlaces(query: String, completion: @escaping (Result<[Place], Error>) -> Void)
    func getPlaceDetails(placeID: String, completion: @escaping (Result<Place, Error>) -> Void)
}

class DefaultPlaceRepository: PlaceRepository {
    private let remoteDataSource: PlaceRemoteDataSource
    private let localDataSource: PlaceLocalDataSource

    init(remoteDataSource: PlaceRemoteDataSource, localDataSource: PlaceLocalDataSource) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }

    func searchPlaces(query: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        remoteDataSource.searchPlaces(query: query) { [weak self] result in
            switch result {
            case .success(let places):
                self?.localDataSource.savePlaces(places)
                completion(.success(places))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getPlaceDetails(placeID: String, completion: @escaping (Result<Place, Error>) -> Void) {
        remoteDataSource.getPlaceDetails(placeID: placeID, completion: completion)
    }
}
