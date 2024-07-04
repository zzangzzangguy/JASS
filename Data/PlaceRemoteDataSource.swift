import Foundation
import Moya

protocol PlaceRemoteDataSource {
    func searchPlaces(query: String, completion: @escaping (Result<[Place], Error>) -> Void)
    func getPlaceDetails(placeID: String, completion: @escaping (Result<Place, Error>) -> Void)
}

class DefaultPlaceRemoteDataSource: PlaceRemoteDataSource {
    private let provider = MoyaProvider<GooglePlacesAPI>()

    func searchPlaces(query: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        provider.request(.placeSearch(input: query)) { result in
            switch result {
            case .success(let response):
                do {
                    let places = try JSONDecoder().decode([Place].self, from: response.data)
                    completion(.success(places))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getPlaceDetails(placeID: String, completion: @escaping (Result<Place, Error>) -> Void) {
        provider.request(.details(placeID: placeID)) { result in
            switch result {
            case .success(let response):
                do {
                    let placeDetails = try JSONDecoder().decode(PlaceDetailsResponse.self, from: response.data)
                    completion(.success(placeDetails.result))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
