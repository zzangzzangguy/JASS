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
    var autoCompleteResults: [String] = []
    var updateAutoCompleteResults: (() -> Void)?
    var showError: ((String) -> Void)?
    
    private let categoriesToTypes: [String: (type: String, keyword: String)] = [
        "헬스": ("gym", "헬스"),
        "필라테스": ("gym", "필라테스"),
        "복싱": ("gym", "복싱"),
        "크로스핏": ("gym", "크로스핏"),
        "골프": ("golf_course", "골프장"),
        "수영": ("gym", "수영장"),
        "클라이밍": ("gym", "클라이밍")
    ]
    
    func searchPlacesInBounds(_ bounds: GMSCoordinateBounds, query: String, completion: @escaping ([Place]) -> Void) {
        guard !query.isEmpty else {
            print("검색어가 비어있습니다. 마커를 업데이트하지 않습니다.")
            completion([])
            return
        }
        
        let center = CLLocationCoordinate2D(latitude: (bounds.northEast.latitude + bounds.southWest.latitude) / 2,
                                            longitude: (bounds.northEast.longitude + bounds.southWest.longitude) / 2)
        let radius = min(bounds.northEast.distance(to: bounds.southWest) / 2, 5000)
        
        let typeAndKeyword = categoriesToTypes[query]
        let type = typeAndKeyword?.type ?? ""
        let keyword = typeAndKeyword?.keyword ?? query
        
        let parameters: [String: Any] = [
            "location": "\(center.latitude),\(center.longitude)",
            "radius": Int(radius),
            "keyword": keyword,
            "type": type
        ]
        
        print("searchPlacesInBounds 검색: \(parameters)")
        
        provider.request(.searchInBounds(parameters: parameters)) { result in
            switch result {
            case .success(let response):
                print("HTTP 상태 코드: \(response.statusCode)")
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
    
    func searchPlace(input: String, category: String, completion: @escaping ([Place]) -> Void) {
        guard let typeAndKeyword = categoriesToTypes[category], !input.isEmpty else {
            completion([])
            return
        }
        
        let type = typeAndKeyword.type
        
        print("searchPlace 검색: \(input), 카테고리: \(category), 타입: \(type)")
        
        provider.request(.textSearch(parameters: ["query": input, "type": type])) { result in
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
    
    func fetchPlacePhoto(reference: String, maxWidth: Int, completion: @escaping (UIImage?) -> Void) {
        provider.request(.photo(reference: reference, maxWidth: maxWidth)) { result in
            switch result {
            case .success(let response):
                if let image = UIImage(data: response.data) {
                    print("사진 요청 성공: \(reference)")
                    completion(image)
                } else {
                    print("사진 데이터 변환 실패: \(reference)")
                    completion(nil)
                }
            case .failure(let error):
                print("사진 요청 실패: \(error.localizedDescription), 참조: \(reference)")
                completion(nil)
            }
        }
    }


    func calculateDistances(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        print("Request Origin: \(originString), Destination: \(destinationString)")
        
        provider.request(.distanceMatrix(origins: originString, destinations: destinationString, mode: "transit", key: Bundle.apiKey)) { result in
            switch result {
            case .success(let response):
                print("거리계산 API 계산: \(response)")
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
                        print("거리 계산: \(distanceText)")
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
    
    func fetchPlaceDetails(placeID: String, completion: @escaping (Place?) -> Void) {
        print("fetchPlaceDetails 호출됨: \(placeID)")
        
        provider.request(.details(placeID: placeID)) { result in
            switch result {
            case .success(let response):
                do {
                    let json = try JSONSerialization.jsonObject(with: response.data, options: .mutableContainers)
                    let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
//                        print("Place Details API Response JSON: \(jsonString)")
                    }
                    
                    let placeDetailsResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: response.data)
                    completion(placeDetailsResponse.result)
                } catch {
                    print("JSON 디코딩 오류: \(error)")
                    completion(nil)
                }
            case .failure(let error):
                print("API 요청 실패: \(error)")
                completion(nil)
            }
        }
    }
    
    func updateDistanceText(for placeID: String, distanceText: String?) {
        if let index = searchResults.firstIndex(where: { $0.place_id == placeID }) {
            searchResults[index].distanceText = distanceText
            updateSearchResults?()
        } else {
            print("PlaceID \(placeID) 검색결과를 찿을수없습니다")
        }
    }
    
    func searchAutoComplete(for query: String, completion: @escaping ([String]) -> Void) {
        let types = "establishment"
        let components = "country:kr"
        provider.request(.autocomplete(input: query, types: types, components: components, language: "ko", location: nil, radius: nil, strictbounds: nil, sessiontoken: nil)) { result in
            switch result {
            case .success(let response):
                do {
                    let autoCompleteResponse = try JSONDecoder().decode(AutoCompleteResponse.self, from: response.data)
                    let suggestions = autoCompleteResponse.predictions.filter { prediction in
                        let keywords = ["헬스", "헬스장", "피트니스", "체육관", "요가", "필라테스", "복싱", "크로스핏", "수영", "클라이밍"]
                        return keywords.contains { keyword in
                            prediction.description.contains(keyword)
                        }
                    }.map { prediction -> String in
                        var description = prediction.description
                        if let range = description.range(of: "대한민국") {
                            description.removeSubrange(range)
                        }
                        return description.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    completion(suggestions)
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
    
    func searchNearbySportsFacilities(at location: CLLocationCoordinate2D, completion: @escaping ([Place]) -> Void) {
        let radius = 5000 // 5km 반경 내에서 검색
        let categories = ["헬스", "필라테스", "복싱", "크로스핏", "골프", "수영", "클라이밍"]
        let group = DispatchGroup()
        var allPlaces: [Place] = []
        
        for category in categories {
            group.enter()
            let parameters: [String: Any] = [
                "location": "\(location.latitude),\(location.longitude)",
                "radius": radius,
                "keyword": category,
                "type": "gym"
            ]
            provider.request(.nearbySearch(parameters: parameters)) { result in
                switch result {
                case .success(let response):
                    do {
                        let searchResults = try JSONDecoder().decode(SearchResults.self, from: response.data)
                        allPlaces.append(contentsOf: searchResults.results)
                    } catch {
                        print("JSON 디코딩 오류: \(error)")
                    }
                case .failure(let error):
                    print("API 요청 실패: \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allPlaces)
        }
    }
}
