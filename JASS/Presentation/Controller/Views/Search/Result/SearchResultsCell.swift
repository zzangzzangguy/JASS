import UIKit
import SnapKit
import Then
import Kingfisher
import GoogleMaps
import GooglePlaces

protocol SearchResultCellDelegate: AnyObject {
    func didTapFavoriteButton(for cell: SearchResultCell)
}

class SearchResultCell: UITableViewCell {
    var placeSearchViewModel: PlaceSearchViewModel?
    static let reuseIdentifier = "SearchResultCell"
    weak var delegate: SearchResultCellDelegate?
    var place: Place?

    private let placeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 10
        $0.backgroundColor = .lightGray
    }

    let nameLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        $0.numberOfLines = 0
    }

    let addressLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .gray
        $0.numberOfLines = 2
    }

    let distanceLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12)
        $0.textColor = .darkGray
    }

    let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.tintColor = .gray
    }

    let reviewsLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12)
        $0.textColor = .darkGray
        $0.numberOfLines = 0
        $0.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        $0.numberOfLines = 2
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var distanceCalculationTask: DispatchWorkItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(placeImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(distanceLabel)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(reviewsLabel)
        contentView.addSubview(loadingIndicator)

        placeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(100)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalTo(placeImageView.snp.trailing).offset(10)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-10)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(5)
            $0.leading.equalTo(nameLabel.snp.leading)
            $0.trailing.equalTo(nameLabel.snp.trailing)
        }

        distanceLabel.snp.makeConstraints {
            $0.top.equalTo(addressLabel.snp.bottom).offset(5)
            $0.leading.equalTo(nameLabel.snp.leading)
            $0.trailing.equalTo(nameLabel.snp.trailing)
        }

        favoriteButton.snp.makeConstraints {
            $0.centerY.equalTo(placeImageView.snp.centerY)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(24)
        }

        reviewsLabel.snp.makeConstraints {
            $0.top.equalTo(distanceLabel.snp.bottom).offset(8)
            $0.leading.equalTo(nameLabel.snp.leading)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview().inset(16)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(placeImageView)
        }

        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }

    func configure(with place: Place, currentLocation: CLLocationCoordinate2D?) {
        print("DEBUG: 셀 구성 시작 - 장소: \(place.name), 거리: \(place.distanceText ?? "없음")")

        self.place = place
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address
        reviewsLabel.text = place.reviews?.compactMap { $0.text }.joined(separator: "\n\n") ?? "리뷰 없음"

        if let distanceText = place.distanceText {
            distanceLabel.text = distanceText
            distanceLabel.isHidden = false
        } else {
            distanceLabel.text = "거리 정보 없음"
            distanceLabel.isHidden = false
        }

        if let photoMetadatas = place.photos {
            loadingIndicator.startAnimating()
            loadFirstPhotoForPlace(place, photoMetadatas: photoMetadatas)
        } else {
            placeImageView.image = UIImage(named: "defaultImage")
            loadingIndicator.stopAnimating()
        }

        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id)
        updateFavoriteButton(isFavorite: isFavorite)

        print("DEBUG: 셀 구성 완료 - 장소: \(place.name), 거리: \(distanceLabel.text ?? "없음")")
    }

    private func loadFirstPhotoForPlace(_ place: Place, photoMetadatas: [Photo]) {
        if let firstPhotoMetadata = photoMetadatas.first {
            loadImageForMetadata(place: place, photo: firstPhotoMetadata)
        } else {
            placeImageView.image = UIImage(named: "defaultImage")
            loadingIndicator.stopAnimating()
        }
    }

    private func loadImageForMetadata(place: Place, photo: Photo) {
        let maxWidth = Int(placeImageView.bounds.size.width)
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: place.place_id) { [weak self] (photoMetadataList: GMSPlacePhotoMetadataList?, error: Error?) in
            guard let self = self else { return }

            self.loadingIndicator.stopAnimating()

            if let error = error {
                self.placeImageView.image = UIImage(named: "defaultImage")
                return
            }

            guard let photoMetadata = photoMetadataList?.results.first else {
                self.placeImageView.image = UIImage(named: "defaultImage")
                return
            }

            GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, constrainedTo: CGSize(width: maxWidth, height: maxWidth), scale: UIScreen.main.scale) { [weak self] (photo: UIImage?, error: Error?) in
                guard let self = self else { return }

                if let error = error {
                    self.placeImageView.image = UIImage(named: "defaultImage")
                } else if let photo = photo {
                    self.placeImageView.image = photo
                }
            }
        }
    }

    @objc private func favoriteButtonTapped() {
        delegate?.didTapFavoriteButton(for: self)
    }

    func updateFavoriteButton(isFavorite: Bool) {
        let heartImage = isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        let tintColor: UIColor = isFavorite ? .red : .gray
        favoriteButton.setImage(heartImage, for: .normal)
        favoriteButton.tintColor = tintColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        distanceLabel.text = "거리 정보 로딩 중..."
        distanceLabel.isHidden = false
        placeImageView.image = nil
        loadingIndicator.stopAnimating()
        distanceCalculationTask?.cancel()
        distanceCalculationTask = nil
    }
}
