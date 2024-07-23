import UIKit
import SnapKit
import GooglePlaces

protocol FavoritePlaceCellDelegate: AnyObject {
    func didTapFavoriteButton(for cell: FavoritePlaceCell, isFavorite: Bool)
}

class FavoritePlaceCell: UITableViewCell {
    static let reuseIdentifier = "FavoritePlaceCell"
    weak var delegate: FavoritePlaceCellDelegate?
    private var place: Place?
    private var photoMetadata: GMSPlacePhotoMetadata?

    private let placeImageView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let favoriteButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(placeImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(loadingIndicator)

        placeImageView.contentMode = .scaleAspectFill
        placeImageView.clipsToBounds = true
        placeImageView.layer.cornerRadius = 10
        placeImageView.backgroundColor = .lightGray

        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameLabel.numberOfLines = 0

        addressLabel.font = UIFont.systemFont(ofSize: 14)
        addressLabel.textColor = .gray
        addressLabel.numberOfLines = 2

        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.tintColor = .gray

        placeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(placeImageView.snp.width).multipliedBy(0.75) // 종횡비를 조정
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(placeImageView.snp.bottom).offset(10)
            $0.leading.equalTo(placeImageView.snp.leading)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-10)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(5)
            $0.leading.equalTo(nameLabel.snp.leading)
            $0.trailing.equalTo(nameLabel.snp.trailing)
            $0.bottom.equalToSuperview().inset(16)
        }

        favoriteButton.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel.snp.centerY)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(24)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(placeImageView)
        }

        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }

    @objc private func favoriteButtonTapped() {
        guard let place = place else { return }
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id)
        delegate?.didTapFavoriteButton(for: self, isFavorite: isFavorite)
    }

    func configure(with place: Place) {
        self.place = place
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address
        placeImageView.image = nil
        loadPlaceImage()
        updateFavoriteButtonImage()
    }

    private func loadPlaceImage() {
        guard let placeID = place?.place_id else {
            setDefaultImage()
            return
        }

        loadingIndicator.startAnimating()

        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeID) { [weak self] (photoMetadataList, error) in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()

            if let error = error {
                self.setDefaultImage()
                return
            }

            guard let photos = photoMetadataList?.results, let firstPhoto = photos.first else {
                self.setDefaultImage()
                return
            }

            self.photoMetadata = firstPhoto
            self.loadImageForMetadata(photoMetadata: firstPhoto)
        }
    }

    private func setDefaultImage() {
        placeImageView.image = UIImage(named: "defaultImage")
        placeImageView.contentMode = .scaleAspectFit
        placeImageView.clipsToBounds = true
    }

    private func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata) { [weak self] (photo, error) -> Void in
            guard let self = self else { return }

            if let error = error {
                self.setDefaultImage()
                return
            }

            if let photo = photo {
                self.placeImageView.image = photo
            } else {
                self.setDefaultImage()
            }
            self.placeImageView.contentMode = .scaleAspectFill
            self.placeImageView.clipsToBounds = true
        }
    }

    private func updateFavoriteButtonImage() {
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place?.place_id ?? "")
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? .red : .gray
    }
}
