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
   let apiKey: String = "apiKey"

   // 텍스트 기반 장소 검색
   func searchPlace(input: String) {
       guard !input.isEmpty else {
           isSearching = false
           print("검색어가 비어 있습니다. 검색을 중단합니다.")
           updateSearchResults?()
           return
       }

       isSearching = true
       print("검색을 시작합니다: \(input)")
       provider.request(.placeSearch(input: input)) { [weak self] result in
           defer {
               self?.isSearching = false
               print("검색 상태가 false로 변경되었습니다.")
           }
           switch result {
           case .success(let response):
               do {
                   let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                   self?.searchResults = searchResults.results
                   print("검색 결과 성공 : \(searchResults.results)")
                   DispatchQueue.main.async {
                       self?.updateSearchResults?()
                   }
               } catch {
                   print("JSON 디코딩 오류 발생: \(error)")
                   DispatchQueue.main.async {
                       self?.showError?("오류 발생: \(error.localizedDescription)")
                   }
               }
           case .failure(let error):
               print("API 요청 실패: \(error)")
               DispatchQueue.main.async {
                   self?.showError?("API 요청 실패: \(error.localizedDescription)")
               }
           }
       }
   }

   func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, completion: @escaping ([Place]) -> Void) {
       isSearching = true
       let northeast = bounds.northEast
       let southwest = bounds.southWest

       print("지도 영역  검색: 북동쪽 \(northeast), 남서쪽 \(southwest)")
       provider.request(.searchInBounds(northeast: northeast, southwest: southwest)) { [weak self] result in
           self?.isSearching = false
           switch result {
           case .success(let response):
               do {
                   let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                   self?.searchResults = searchResults.results
                   print("지도 영역 검색 성공: \(searchResults.results)")
                   completion(searchResults.results)
               } catch {
                   print("JSON 디코딩 오류 발생: \(error)")
                   self?.showError?("오류 발생: \(error.localizedDescription)")
               }
           case .failure(let error):
               print("API 요청 실패: \(error)")
               self?.showError?("API 요청 실패: \(error.localizedDescription)")
           }
       }
   }

   func searchPlacesNearCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double, bounds: GMSCoordinateBounds, completion: @escaping ([Place]) -> Void) {
       let location = "\(coordinate.latitude),\(coordinate.longitude)"
       let type = "gym"
       let parameters: [String: String] = [
           "location": location,
           "radius": "\(radius)",
           "type": type,
           "key": apiKey
       ]

       provider.request(.nearbySearch(parameters: parameters), callbackQueue: DispatchQueue.main) { result in
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
}
