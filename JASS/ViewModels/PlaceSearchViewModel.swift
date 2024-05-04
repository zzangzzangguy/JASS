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
  let apiKey: String = "API_KEY"

  func searchPlacesNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, types: [String], completion: @escaping ([Place]) -> Void) {
      let location = "\(coordinate.latitude),\(coordinate.longitude)"
      let parameters: [String: String] = [
             "location": location,
             "radius": "\(Int(radius))",
             "type": types.joined(separator: "|"),
             "key": Bundle.apiKey
         ]

      provider.request(.nearbySearch(parameters: parameters)) { result in
          switch result {
          case .success(let response):
              do {
                  let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                  print("API 호출 성공: \(searchResults.results.count)개의 장소 발견.")
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

   func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, types: [String], completion: @escaping ([Place]) -> Void) {
       let northeast = bounds.northEast
       let southwest = bounds.southWest
       let typeFilter = types.joined(separator: "|")
       print("요청 types: \(types)") // 요청 types 출력

       let parameters: [String: Any] = [
           "key": Bundle.apiKey,
           "northeast": "\(northeast.latitude),\(northeast.longitude)",
           "southwest": "\(southwest.latitude),\(southwest.longitude)",
           "type": typeFilter
       ]

       provider.request(.searchInBounds(parameters: parameters)) { result in
          switch result {
          case .success(let response):
              do {
                  let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                  print("API 응답 데이터: \(searchResults)") // 응답 데이터 출력
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
      print("검색 :\(parameters)")

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

  func fetchPlacePhoto(reference: String, maxWidth: Int, completion: @escaping (URL?) -> Void) {  // 추가: fetchPlacePhoto 메서드 추가
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
