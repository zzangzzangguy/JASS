import Foundation
import Moya
import GoogleMaps
import CoreLocation

struct SearchResults: Codable {
    let results: [Place]
}

class PlaceSearchViewModel {
    let provider = MoyaProvider<GooglePlacesAPI>()
    var searchResults: [Place] = []
    var isSearching: Bool = false
    var updateSearchResults: (() -> Void)?
    var showError: ((String) -> Void)?

    func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, query: String, completion: @escaping ([Place]) -> Void) {
        guard !query.isEmpty else {
            print("검색어가 비어있습니다. 마커를 업데이트하지 않습니다.")
            completion([])
            return
        }

        let center = CLLocationCoordinate2D(latitude: (bounds.northEast.latitude + bounds.southWest.latitude) / 2,
                                            longitude: (bounds.northEast.longitude + bounds.southWest.longitude) / 2)
        let radius = min(bounds.northEast.distance(to: bounds.southWest) / 2, 5000)

        let parameters: [String: Any] = [
            "location": "\(center.latitude),\(center.longitude)",
            "radius": Int(radius),
            "keyword": query
        ]

        print("searchPlacesInBounds 검색 : \(parameters)")

        provider.request(.searchInBounds(parameters: parameters)) { result in
            switch result {
            case .success(let response):
                print("HTTP 상태 코드: \(response.statusCode)")
                do {
                    let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                    print("API 응답 데이터: \(searchResults)")
                    completion(searchResults.results)
                } catch {
                    print("JSON 디코딩 오류: \(error)")
                    completion([])
                }
            case .failure(let error):
                print("API 요청 실패: \(error)")
                completion([])
            }
        }
    }

    func searchPlace(input: String, completion: @escaping ([Place]) -> Void) {
        guard !input.isEmpty else {
            completion([])
            return
        }

        print("searchPlace 검색 : \(input)")

        provider.request(.textSearch(parameters: ["query": input])) { result in
            switch result {
            case .success(let response):
                do {
                    var searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                    completion(searchResults.results)
                    
                } catch {
                    print("JSON 디코딩 오류: \(error)")
                    completion([])
                }
            case .failure(let error):
                print("API 요청 실패: \(error)")
                completion([])
            }
        }
    }

    func fetchPlacePhoto(reference: String, maxWidth: Int, completion: @escaping (URL?) -> Void) {
        provider.request(.photo(reference: reference, maxWidth: maxWidth)) { result in
            switch result {
            case .success(let response):
                if let urlString = try? response.mapString(), let url = URL(string: urlString) {
                    completion(url)
                } else {
                    completion(nil)
                }
            case .failure(let error):
                print("사진 요청 실패: \(error)")
                completion(nil)
            }
        }
    }

    func calculateDistances(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let originString = "\(origin.latitude),\(origin.longitude)|kr"
        let destinationString = "\(destination.latitude),\(destination.longitude)|kr"
        print("Request Origin: \(originString), Destination: \(destinationString)")

        provider.request(.distanceMatrix(origins: originString, destinations: destinationString, mode: "transit", key: Bundle.apiKey)) { result in
            switch result {
            case .success(let response):
                print("Distance Matrix API Response: \(response)")
                do {
                    if let json = try? JSONSerialization.jsonObject(with: response.data, options: .mutableContainers),
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("Distance Matrix API Response JSON: \(jsonString)")
                    }

                    let distanceMatrix = try JSONDecoder().decode(DistanceMatrixResponse.self, from: response.data)
                    if let element = distanceMatrix.rows.first?.elements.first,
                       let distance = element.distance {
                        let distanceText = distance.text
                        print("Calculated Distance: \(distanceText)")
                        completion(distanceText)
                    } else {
                        print("Distance calculation returned nil element")
                        completion(nil)
                    }
                } catch {
                    print("거리 계산 JSON 디코딩 오류: \(error)")
                    completion(nil)
                }
            case .failure(let error):
                print("거리 계산 API 요청 실패: \(error)")
                completion(nil)
            }
        }
    }
}
