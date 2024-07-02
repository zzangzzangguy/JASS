import Foundation
import UIKit
import RxSwift

class GymDetailViewModel {
    private let placeID: String
    private let placeSearchViewModel: PlaceSearchViewModel
    private let disposeBag = DisposeBag()

    var placeDetails: Place? {
        didSet {
            self.onPlaceDetailsUpdated?()
        }
    }

    var onPlaceDetailsUpdated: (() -> Void)?

    init(placeID: String, placeSearchViewModel: PlaceSearchViewModel) {
        self.placeID = placeID
        self.placeSearchViewModel = placeSearchViewModel
        loadPlaceDetails()
    }

    func loadImages(completion: @escaping ([UIImage]) -> Void) {
        guard let place = placeDetails, let photos = place.photos else {
            completion([])
            return
        }

        var loadedImages: [UIImage] = []
        let group = DispatchGroup()

        for photo in photos {
            group.enter()
            placeSearchViewModel.fetchPlacePhoto(reference: photo.photoReference, maxWidth: 1000)
                .subscribe(onNext: { image in
                    if let image = image {
                        loadedImages.append(image)
                    }
                    group.leave()
                }, onError: { error in
                    print("Error loading image: \(error)")
                    group.leave()
                })
                .disposed(by: disposeBag)
        }

        group.notify(queue: .main) {
            completion(loadedImages)
        }
    }
    func loadPlaceDetails() {
        placeSearchViewModel.fetchPlaceDetails(placeID: placeID) { [weak self] place in
            guard let self = self, let place = place else { return }
            self.placeDetails = place
        }
    }
}
