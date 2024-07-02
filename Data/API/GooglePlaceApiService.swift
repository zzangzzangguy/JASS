import Foundation
import UIKit
import RxSwift
import RxMoya
import Moya

struct SearchResults: Codable {
    let results: [Place]
}

class GooglePlacesAPIService {
    private let provider = MoyaProvider<GooglePlacesAPI>()

    func searchPlaces(query: String) -> Observable<[Place]> {
        return provider.rx.request(.placeSearch(input: query))
            .filterSuccessfulStatusCodes()
            .map(SearchResults.self)
            .map { $0.results }
            .asObservable()
    }

    func searchPlacesInBounds(parameters: [String: Any]) -> Observable<[Place]> {
        return provider.rx.request(.searchInBounds(parameters: parameters))
            .filterSuccessfulStatusCodes()
            .map(SearchResults.self)
            .map { $0.results }
            .asObservable()
    }

    func getPlaceDetails(placeID: String) -> Observable<Place> {
        return provider.rx.request(.details(placeID: placeID))
            .filterSuccessfulStatusCodes()
            .map(PlaceDetailsResponse.self)
            .map { $0.result }
            .asObservable()
    }

    func getPlacePhotos(reference: String, maxWidth: Int) -> Observable<UIImage?> {
        return provider.rx.request(.photo(reference: reference, maxWidth: maxWidth))
            .filterSuccessfulStatusCodes()
            .mapImage()
            .asObservable()
            .compactMap { $0 }
    }

    func getAutocomplete(query: String) -> Observable<[String]> {
        let types = "establishment"
        let components = "country:kr"
        return provider.rx.request(.autocomplete(input: query, types: types, components: components, language: "ko", location: nil, radius: nil, strictbounds: nil, sessiontoken: nil))
            .filterSuccessfulStatusCodes()
            .map(AutoCompleteResponse.self)
            .map { response in
                response.predictions.map { $0.description }
            }
            .asObservable()
    }

    func calculateDistances(origins: String, destinations: String) -> Observable<String?> {
        return provider.rx.request(.distanceMatrix(origins: origins, destinations: destinations, mode: "transit", key: Bundle.apiKey))
            .filterSuccessfulStatusCodes()
            .map(DistanceMatrixResponse.self)
            .map { response in
                if let element = response.rows.first?.elements.first, let distance = element.distance {
                    return distance.text
                }
                return nil
            }
            .asObservable()
    }

    func searchNearby(parameters: [String: Any]) -> Observable<[Place]> {
        return provider.rx.request(.nearbySearch(parameters: parameters))
            .filterSuccessfulStatusCodes()
            .map(SearchResults.self)
            .map { $0.results }
            .asObservable()
    }
}
