// Data/API/GooglePlacesAPI.swift
import Foundation
import Moya

enum GooglePlacesAPI {
    case placeSearch(input: String)
    case searchInBounds(parameters: [String: Any])
    case nearbySearch(parameters: [String: Any])
    case textSearch(parameters: [String: Any])
    case photo(reference: String, maxWidth: Int)
    case distanceMatrix(origins: String, destinations: String, mode: String, key: String)
    case details(placeID: String)
    case autocomplete(input: String, types: String, components: String?, language: String?, location: String?, radius: Int?, strictbounds: Bool?, sessiontoken: String?)
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
        case .searchInBounds, .nearbySearch:
            return "/nearbysearch/json"
        case .textSearch:
            return "/textsearch/json"
        case .photo:
            return "/photo"
        case .distanceMatrix:
            return "/distancematrix/json"
        case .details:
            return "/details/json"
        case .autocomplete:
            return "/autocomplete/json"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case .placeSearch(let input):
            return .requestParameters(parameters: ["key": Bundle.apiKey, "query": input], encoding: URLEncoding.queryString)
        case .photo(let reference, let maxWidth):
            return .requestParameters(parameters: ["maxwidth": maxWidth, "photoreference": reference, "key": Bundle.apiKey], encoding: URLEncoding.queryString)
        case .details(let placeID):
            return .requestParameters(parameters: ["place_id": placeID, "fields": "place_id,reviews,name,geometry,formatted_address,photos", "key": Bundle.apiKey], encoding: URLEncoding.queryString)

        case .searchInBounds(let parameters), .nearbySearch(let parameters), .textSearch(let parameters):
            var newParameters = parameters
            newParameters["key"] = Bundle.apiKey
            return .requestParameters(parameters: newParameters, encoding: URLEncoding.queryString)
        case .distanceMatrix(let origins, let destinations, let mode, let key):
            return .requestParameters(parameters: ["origins": origins, "destinations": destinations, "mode": "transit", "key": key], encoding: URLEncoding.default)
        case .autocomplete(let input, let types, let components, let language, let location, let radius, let strictbounds, let sessiontoken):
            var parameters: [String: Any] = [
                "input": input,
                "types": types,
                "key": Bundle.apiKey
            ]
            if let components = components { parameters["components"] = components }
            if let language = language { parameters["language"] = language }
            if let location = location { parameters["location"] = location }
            if let radius = radius { parameters["radius"] = radius }
            if let strictbounds = strictbounds { parameters["strictbounds"] = strictbounds }
            if let sessiontoken = sessiontoken { parameters["sessiontoken"] = sessiontoken }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
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
