import Foundation
import Moya
import GoogleMaps

struct SearchResults: Codable {
  let results: [Place]
}

class PlaceSearchViewModel {
  let provider = MoyaProvider<GooglePlacesAPI>()
  var searchResults: [Place] = []
  var isSearching: Bool = false
  var updateSearchResults: (() -> Void)?
  var showError: ((String) -> Void)?
  let apiKey: String = "API_KEY"

//  func searchPlacesNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, types: [String], completion: @escaping ([Place]) -> Void) {
//      let location = "\(coordinate.latitude),\(coordinate.longitude)"
//      let parameters: [String: String] = [
//             "location": location,
//             "radius": "\(Int(radius))",
//             "type": types.joined(separator: "|"),
//             "key": Bundle.apiKey,
//         ]
//      print("searchPlacesNearCoordinate \(parameters)")
//
//
//      provider.request(.nearbySearch(parameters: parameters)) { result in
//          switch result {
//          case .success(let response):
//              do {
//                  let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
//                  print("API 호출 성공: \(searchResults.results.count)개의 장소 발견.")
//                  completion(searchResults.results)
//              } catch {
//                  print("JSON 디코딩 오류: \(error)")
//                  completion([])
//              }
//          case .failure(let error):
//              print("API 요청 실패: \(error)")
//              completion([])
//          }
//      }
//  }

    func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, query: String, completion: @escaping ([Place]) -> Void) {
        let center = CLLocationCoordinate2D(latitude: (bounds.northEast.latitude + bounds.southWest.latitude) / 2,
                                            longitude: (bounds.northEast.longitude + bounds.southWest.longitude) / 2)
        let radius = min(bounds.northEast.distance(to: bounds.southWest) / 2, 5000) // API의 최대 지원 반경은 50,000 미터

        let parameters: [String: Any] = [
            "key": apiKey,
            "location": "\(center.latitude),\(center.longitude)",
            "radius": Int(radius),
            "keyword": query
        ]

        print(" searchPlacesInBounds 검색 : \(parameters)")


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

      let parameters: [String: Any] = [
          "key": apiKey,
          "query": input
      ]
      print(" searchPlace 검색 :\(parameters)")

      provider.request(.textSearch(parameters: parameters)) { result in
          switch result {
          case .success(let response):
              do {
                  let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
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
}
