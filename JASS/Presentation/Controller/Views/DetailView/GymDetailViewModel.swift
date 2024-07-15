import Foundation
import RxCocoa
import RxSwift
import UIKit

class GymDetailViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let favoriteButtonTapped: Observable<Void>
        let loadImages: Observable<Void>
    }

    struct Output {
        let placeDetails: Driver<Place?>
        let isLoading: Driver<Bool>
        let favoriteStatus: Driver<Bool>
        let images: Driver<[UIImage]>
    }

    let placeID: String
    private let placeSearchViewModel: PlaceSearchViewModel
    var disposeBag = DisposeBag()
    let favoriteToggle = PublishRelay<String>()

    init(placeID: String, placeSearchViewModel: PlaceSearchViewModel) {
        self.placeID = placeID
        self.placeSearchViewModel = placeSearchViewModel
    }

    func transform(input: Input) -> Output {
        let isLoading = BehaviorRelay<Bool>(value: false)

        let placeDetails = input.viewDidLoad
            .do(onNext: { isLoading.accept(true) })
            .flatMapLatest { [weak self] _ -> Observable<Place?> in
                guard let self = self else { return .just(nil) }
                return self.loadPlaceDetails()
            }
            .do(onNext: { _ in isLoading.accept(false) })
            .share(replay: 1)

        let favoriteStatus = input.favoriteButtonTapped
            .withLatestFrom(placeDetails)
            .map { [weak self] place -> Bool in
                guard let place = place else { return false }
                self?.updateFavoriteStatus(for: place)
                return FavoritesManager.shared.isFavorite(placeID: place.place_id)
            }

        let images = input.loadImages
            .withLatestFrom(placeDetails)
            .flatMapLatest { [weak self] place -> Observable<[UIImage]> in
                guard let self = self, let place = place else { return .just([]) }
                return self.loadImages(for: place)
            }

        return Output(
            placeDetails: placeDetails.asDriver(onErrorJustReturn: nil),
            isLoading: isLoading.asDriver(),
            favoriteStatus: favoriteStatus.asDriver(onErrorJustReturn: false),
            images: images.asDriver(onErrorJustReturn: [])
        )
    }

    private func loadPlaceDetails() -> Observable<Place?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            self.placeSearchViewModel.fetchPlaceDetails(placeID: self.placeID) { place in
                observer.onNext(place)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    private func updateFavoriteStatus(for place: Place) {
        FavoritesManager.shared.toggleFavorite(place: place)
        favoriteToggle.accept(place.place_id)
    }

    private func loadImages(for place: Place) -> Observable<[UIImage]> {
        guard let photos = place.photos, !photos.isEmpty else {
            return .just([])
        }

        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            var loadedImages: [UIImage] = []
            let group = DispatchGroup()

            for photo in photos {
                group.enter()
                self.placeSearchViewModel.fetchPlacePhoto(reference: photo.photoReference, maxWidth: 1000)
                    .subscribe(onNext: { image in
                        if let image = image {
                            loadedImages.append(image)
                        }
                        group.leave()
                    }, onError: { _ in
                        group.leave()
                    })
                    .disposed(by: self.disposeBag)
            }

            group.notify(queue: .main) {
                observer.onNext(loadedImages)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
