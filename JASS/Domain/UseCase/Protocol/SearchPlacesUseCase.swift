import Foundation

protocol SearchPlacesUseCase {
    func execute(query: String, pageToken: String?, pageSize: Int, completion: @escaping (Result<([Place], String?), Error>) -> Void)
}
