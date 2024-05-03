import UIKit
import SnapKit
import Kingfisher
import GoogleMaps

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
        

        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place.place_id)
        favoriteButton.tintColor = isFavorite ? .red : .gray
    }

    
    @objc private func favoriteButtonTapped() {
        delegate?.didTapFavoriteButton(for: self)
    }
}
