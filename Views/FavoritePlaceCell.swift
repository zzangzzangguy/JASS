import UIKit
import SnapKit

protocol FavoritePlaceCellDelegate: AnyObject {
    func didTapFavoriteButton(for cell: FavoritePlaceCell, isFavorite: Bool)
}

class FavoritePlaceCell: UITableViewCell {
    static let reuseIdentifier = "FavoritePlaceCell"

    weak var delegate: FavoritePlaceCellDelegate?

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()

    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .red
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(favoriteButton)

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
        }

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
            make.trailing.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-8)
        }

        favoriteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(24)
        }

        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }

    @objc private func favoriteButtonTapped() {
        delegate?.didTapFavoriteButton(for: self, isFavorite: FavoritesManager.shared.isFavorite(placeID: place?.place_id ?? ""))
    }

    func configure(with place: Place) {
        self.place = place
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address
        updateFavoriteButtonImage()
    }

    private func updateFavoriteButtonImage() {
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: place?.place_id ?? "")
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private var place: Place?
}
