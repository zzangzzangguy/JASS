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
    let nameLabel = UILabel()
    let addressLabel = UILabel()
    let favoriteButton = UIButton(type: .system)
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

        placeImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(100)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.equalTo(placeImageView.snp.trailing).offset(10)
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-10)
        }

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.leading.equalTo(nameLabel.snp.leading)
            make.trailing.equalTo(nameLabel.snp.trailing)
            make.bottom.equalToSuperview().inset(16) // 셀의 하단에 고정
        }

        favoriteButton.snp.makeConstraints { make in
            make.centerY.equalTo(placeImageView.snp.centerY)
            make.trailing.equalToSuperview().inset(20)
            make.width.height.equalTo(24)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(placeImageView)
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
            placeImageView.image = UIImage(named: "defaultImage")
            return
        }

        loadingIndicator.startAnimating()

        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeID) { [weak self] (photoMetadataList, error) in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()

            if let error = error {
                self.placeImageView.image = UIImage(named: "defaultImage")
                return
            }

            guard let photos = photoMetadataList?.results, let firstPhoto = photos.first else {
                self.placeImageView.image = UIImage(named: "defaultImage")
                return
            }

            self.photoMetadata = firstPhoto
            self.loadImageForMetadata(photoMetadata: firstPhoto)
        }
    }

    private func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata) { [weak self] (photo, error) -> Void in
            guard let self = self else { return }

            if let error = error {
                self.placeImageView.image = UIImage(named: "defaultImage")
                return
            }

            if let photo = photo {
                self.placeImageView.image = photo
            } else {
                self.placeImageView.image = UIImage(named: "defaultImage")
            }
        }
    }

    private func updateFavoriteButtonImage() {
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place?.place_id ?? "")
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? .red : .gray
    }
}
