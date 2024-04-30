import Moya
import GoogleMaps

enum GooglePlacesAPI {
    case placeSearch(input: String)
    case searchInBounds(parameters: [String: Any])
    case nearbySearch(parameters: [String: String])
    case textSearch(parameters: [String: Any])
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
