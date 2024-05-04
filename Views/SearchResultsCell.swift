import UIKit
import SnapKit
import Kingfisher
import GoogleMaps
import GooglePlaces

class SearchResultCell: UITableViewCell {
    static let reuseIdentifier = "SearchResultCell"

    private let placeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 40
        $0.backgroundColor = .lightGray
    }

    let nameLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        $0.numberOfLines = 0
    }

    let addressLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .gray
        $0.numberOfLines = 0
    }

    let distanceLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12)
        $0.textColor = .darkGray
    }

    let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.tintColor = .gray
    }

    weak var delegate: SearchResultCellDelegate?

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

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
        contentView.addSubview(loadingIndicator)

        placeImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(80)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.equalTo(placeImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(20)
        }

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.leading.equalTo(nameLabel.snp.leading)
            make.trailing.equalTo(nameLabel.snp.trailing)
        }

        distanceLabel.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(5)
            make.leading.equalTo(nameLabel.snp.leading)
            make.trailing.equalTo(nameLabel.snp.trailing)
        }

        favoriteButton.snp.makeConstraints { make in
            make.centerY.equalTo(placeImageView.snp.centerY)
            make.trailing.equalToSuperview().inset(20)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(placeImageView)
        }

        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }

    func configure(with place: Place, currentLocation: CLLocationCoordinate2D?) {
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address

        if let currentLocation = currentLocation {
            let distance = GMSGeometryDistance(currentLocation, place.coordinate) / 1000
            distanceLabel.text = String(format: "%.1f km", distance)
        } else {
            distanceLabel.text = "거리 정보 없음"
        }

        if let photoMetadatas = place.photos {
               loadingIndicator.startAnimating()
               loadFirstPhotoForPlace(place, photoMetadatas: photoMetadatas)
           } else {
               placeImageView.image = UIImage(named: "defaultImage")
               loadingIndicator.stopAnimating()
           }


        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id)
        favoriteButton.tintColor = isFavorite ? .red : .gray
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
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: place.place_id) { [weak self] (photoMetadataList, error) in
            guard let self = self else { return }

            self.loadingIndicator.stopAnimating()

            if let error = error {
                print("Error loading photo: \(error.localizedDescription)")
                self.placeImageView.image = UIImage(named: "defaultImage")
                return
            }

            guard let photoMetadata = photoMetadataList?.results.first else {
                self.placeImageView.image = UIImage(named: "defaultImage")
                return
            }

            GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, constrainedTo: CGSize(width: maxWidth, height: maxWidth), scale: UIScreen.main.scale) { [weak self] (photo, error) in
                guard let self = self else { return }

                if let error = error {
                    print("Error loading photo: \(error.localizedDescription)")
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
}
