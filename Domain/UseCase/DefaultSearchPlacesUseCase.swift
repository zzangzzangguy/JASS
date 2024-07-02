import Foundation
import RxSwift

class DefaultSearchPlacesUseCase: SearchPlacesUseCase {
    private let repository: PlaceRepository
    private let disposeBag = DisposeBag()

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func execute(query: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        repository.searchPlaces(query: query)
            .subscribe(onNext: { places in
                completion(.success(places))
            }, onError: { error in
                completion(.failure(error))
            })
            .disposed(by: disposeBag)
    }
}
