import Moya
import GoogleMaps

enum GooglePlacesAPI {
    case placeSearch(input: String)
    case searchInBounds(northeast: CLLocationCoordinate2D, southwest: CLLocationCoordinate2D)

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
          }
      }


    var method: Moya.Method {
        return .get
    }

    var task: Task {
           switch self {
           case let .placeSearch(input):
               if let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
                   return .requestParameters(parameters: [
                       "key": apiKey,
                       "query": input
                   ], encoding: URLEncoding.queryString)
               }
               fatalError("API 키를 로드할 수 없음")

           case let .searchInBounds(northeast, southwest):
               if let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
                   let parameters: [String: Any] = [
                       "key": apiKey,
                       "location": "\(northeast.latitude),\(northeast.longitude)",
                       "radius": 5000,
                       "keyword": "health|pilates|fitness|swimming|gym|yoga"
                   ]
                   return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
               }
               fatalError("API 키를 로드할 수 없음")
           }
       }


    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
