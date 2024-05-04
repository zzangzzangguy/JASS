import Moya
import GoogleMaps

enum GooglePlacesAPI {
   case placeSearch(input: String)
   case searchInBounds(parameters: [String: Any])
   case nearbySearch(parameters: [String: String])
   case textSearch(parameters: [String: Any])
   case photo(reference: String, maxWidth: Int)  // 추가: 사진 API 추가
}

extension GooglePlacesAPI: TargetType {
   var baseURL: URL {
       return URL(string: "https://maps.googleapis.com/maps/api/place")!
   }

   var path: String {
       switch self {
       case .placeSearch:
           return "/textsearch/json"
       case .searchInBounds:
           return "/nearbysearch/json"
       case .nearbySearch:
           return "/nearbysearch/json"
       case .textSearch:
           return "/textsearch/json"
       case .photo:
           return "/photo"  // 추가: 사진 경로 추가
       }
   }

   var method: Moya.Method {
       return .get
   }

   var task: Task {
       switch self {
       case .placeSearch(let input):
           return .requestParameters(parameters: [
               "key": Bundle.apiKey,
               "query": input
           ], encoding: URLEncoding.queryString)
       case .photo(let reference, let maxWidth):  // 추가: 사진 요청 매개변수 추가
           let parameters: [String: Any] = [
               "maxwidth": maxWidth,
               "photoreference": reference,
               "key": Bundle.apiKey
           ]
           return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
       case .searchInBounds(let parameters):
           var newParameters = parameters
           newParameters["key"] = Bundle.apiKey
           return .requestParameters(parameters: newParameters, encoding: URLEncoding.queryString)
       case .nearbySearch(let parameters):
           var newParameters = parameters
           newParameters["key"] = Bundle.apiKey
           return .requestParameters(parameters: newParameters, encoding: URLEncoding.queryString)
       case .textSearch(let parameters):
           var newParameters = parameters
           newParameters["key"] = Bundle.apiKey
           return .requestParameters(parameters: newParameters, encoding: URLEncoding.queryString)
       }
   }

   var headers: [String: String]? {
       return ["Content-Type": "application/json"]
   }
}

extension Bundle {
   static var apiKey: String {
       guard let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String else {
           fatalError("API_KEY not found in .xcconfig file")
       }
       return apiKey
   }
}
