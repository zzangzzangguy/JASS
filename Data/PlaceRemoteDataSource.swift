import Foundation
import RxSwift
import Moya

protocol PlaceRemoteDataSource {
    func searchPlaces(query: String, pageToken: String?, pageSize: Int) -> Observable<([Place], String?)>
    func getPlaceDetails(placeID: String) -> Observable<Place>
}

class DefaultPlaceRemoteDataSource: PlaceRemoteDataSource {
    private let provider = MoyaProvider<GooglePlacesAPI>()

    func searchPlaces(query: String, pageToken: String?, pageSize: Int) -> Observable<([Place], String?)> {
        return Observable.create { observer in
            self.provider.request(.placeSearch(parameters: ["query": query, "pageToken": pageToken, "pageSize": pageSize])) { result in
                switch result {
                case .success(let response):
                    do {
                        let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
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
    }

    func getPlaceDetails(placeID: String) -> Observable<Place> {
        return Observable.create { observer in
            self.provider.request(.details(placeID: placeID)) { result in
                switch result {
                case .success(let response):
                    do {
                        let placeDetails = try JSONDecoder().decode(PlaceDetailsResponse.self, from: response.data)
                        observer.onNext(placeDetails.result)
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
    }
}
