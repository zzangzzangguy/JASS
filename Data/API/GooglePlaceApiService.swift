import Foundation
import UIKit
import GoogleMaps
import RxSwift
//import RxMoya
import Moya

struct SearchResults: Codable {
    let results: [Place]
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
            case results
            case nextPageToken = "next_page_token"
        }
    }

class GooglePlacesAPIService {
    private let provider = MoyaProvider<GooglePlacesAPI>()

    func searchPlaces(query: String, pageToken: String? = nil) -> Observable<([Place], String?)> {
        var parameters: [String: Any] = ["key": Bundle.apiKey, "query": query]
        if let pageToken = pageToken {
            parameters["pagetoken"] = pageToken
        }
        print("DEBUG: API 호출 - \(parameters)")

        return Observable.create { observer in
            self.provider.request(.placeSearch(parameters: parameters)) { result in
                switch result {
                case .success(let response):
                    do {
                        let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                        // next_page_token이 제대로 반환되는지 확인
//                        print("DEBUG: API 응답 데이터 - \(String(data: response.data, encoding: .utf8) ?? "")")
                        observer.onNext((searchResults.results, searchResults.nextPageToken))
                        observer.onCompleted()
                    } catch {
                        observer.onError(error)
                    }
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
        .delaySubscription(.seconds(2), scheduler: MainScheduler.instance) // Google Places API 특성상 필요
        .do(onNext: { (results, nextPageToken) in
            print("DEBUG: API 응답 결과 - \(results.count)개, 다음 페이지 토큰 - \(String(describing: nextPageToken))")
        }, onError: { error in
            print("DEBUG: API 호출 중 오류 - \(error.localizedDescription)")
        })
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

    func calculateDistances(origins: String, destinations: String) -> Observable<[String?]> {
        return provider.rx.request(.distanceMatrix(origins: origins, destinations: destinations, mode: "transit", key: Bundle.apiKey))
            .filterSuccessfulStatusCodes()
            .map(DistanceMatrixResponse.self)
            .asObservable()
            .do(onNext: { response in
                // print("DEBUG: API 응답 전체: \(response)")
            })
            .map { response in
                return response.rows.first?.elements.map { $0.distance?.text } ?? []
            }
            .catch { error in
                print("DEBUG: API 오류 발생: \(error)")
                return Observable.just([])
            }
    }

    func searchNearby(parameters: [String: Any]) -> Observable<[Place]> {
        return provider.rx.request(.nearbySearch(parameters: parameters))
            .filterSuccessfulStatusCodes()
            .map(SearchResults.self)
            .map { $0.results }
            .asObservable()
    }
}
