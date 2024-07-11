import Foundation
import RxCocoa
import RxSwift
import UIKit


class GymDetailViewModel {
    private let placeID: String
    private let placeSearchViewModel: PlaceSearchViewModel
    private let disposeBag = DisposeBag()
    let favoriteToggle = PublishRelay<String>() // 추가된 부분


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
        guard let place = placeDetails else {
            print("사진 출력 실패. 장소 세부 정보가 없습니다.")
            completion([])
            return
        }

        guard let photos = place.photos, !photos.isEmpty else {
            print("사진 출력 실패. 사진이 없습니다.")
            print("Place details: \(place)")
            completion([])
            return
        }

        var loadedImages: [UIImage] = []
        let group = DispatchGroup()

        for photo in photos {
            group.enter()
            print("사진 로드 시도 - 참조: \(photo.photoReference)")
            placeSearchViewModel.fetchPlacePhoto(reference: photo.photoReference, maxWidth: 1000)
                .subscribe(onNext: { image in
                    if let image = image {
                        print("사진 로드 성공 - 참조: \(photo.photoReference)")
                        loadedImages.append(image)
                    } else {
                        print("사진 로드 실패 - 참조: \(photo.photoReference), 이미지가 nil입니다.")
                    }
                    group.leave()
                }, onError: { error in
                    print("사진 로드 오류 발생: \(error.localizedDescription)")
                    group.leave()
                })
                .disposed(by: disposeBag)
        }

        group.notify(queue: .main) {
            print("모든 사진 로드 완료. 총 로드된 사진 수: \(loadedImages.count)")
            completion(loadedImages)
        }
    }

    func loadPlaceDetails() {
        placeSearchViewModel.fetchPlaceDetails(placeID: placeID) { [weak self] place in
            guard let self = self else { return }
            if let place = place {
                print("장소 세부 정보 로드 성공: \(place)")
                self.placeDetails = place
            } else {
                print("장소 세부 정보 로드 실패")
            }
        }
    }
}
