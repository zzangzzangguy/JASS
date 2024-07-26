import Foundation
import RxSwift

class DefaultSearchPlacesUseCase: SearchPlacesUseCase {
    private let repository: PlaceRepository
    private let disposeBag = DisposeBag()

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func execute(query: String, pageToken: String? = nil, pageSize: Int = 10, completion: @escaping (Result<([Place], String?), Error>) -> Void) {
        repository.searchPlaces(query: query, pageToken: pageToken)
            .subscribe(onNext: { places, nextPageToken in
                completion(.success((places, nextPageToken)))
            }, onError: { error in
                completion(.failure(error))
            })
            .disposed(by: disposeBag)
    }
}
