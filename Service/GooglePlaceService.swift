import Moya
import GoogleMaps

enum GooglePlacesAPI {
    case placeSearch(input: String)
    case searchInBounds(parameters: [String: Any])
    case nearbySearch(parameters: [String: String])
    case textSearch(parameters: [String: Any])
    case photo(reference: String, maxWidth: Int)
    case distanceMatrix(origins: String, destinations: String, mode: String, key: String)
    case details(placeID: String)
}

extension GooglePlacesAPI: TargetType {
    var baseURL: URL {
        switch self {
        case .distanceMatrix:
            return URL(string: "https://maps.googleapis.com/maps/api")!
        default:
            return URL(string: "https://maps.googleapis.com/maps/api/place")!
        }
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
            return "/photo"
        case .distanceMatrix:
            return "/distancematrix/json"
        case .details:
            return "/details/json"
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
        case .photo(let reference, let maxWidth):  
            let parameters: [String: Any] = [
                "maxwidth": maxWidth,
                "photoreference": reference,
                "key": Bundle.apiKey
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .details(let placeID):
                    return .requestParameters(parameters: [
                        "place_id": placeID,
                        "fields": "place_id,reviews,name,geometry,formatted_address",
                        "key": Bundle.apiKey
                    ], encoding: URLEncoding.queryString)        case .searchInBounds(let parameters):
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
        case let .distanceMatrix(origins, destinations, mode, key):
            return .requestParameters(parameters: ["origins": origins, "destinations": destinations, "mode": mode, "key": key], encoding: URLEncoding.default)
        }
    }
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}

extension Bundle {
    static var apiKey: String {
        guard let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String else {
            fatalError("api key 찿을수없음")
        }
        return apiKey
    }
}
