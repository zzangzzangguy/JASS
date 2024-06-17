import UIKit
import SnapKit
import Then
import GooglePlaces

protocol FacilityCollectionViewCellDelegate: AnyObject {
    func didTapFacilityCell(_ cell: FacilityCollectionViewCell, place: Place)
}

final class FacilityCollectionViewCell: UICollectionViewCell {
    static let identifier = "FacilityCollectionViewCell"
    private let placeSearchViewModel = PlaceSearchViewModel()
    weak var delegate: FacilityCollectionViewCellDelegate?
    private var place: Place?

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8

        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        addressLabel.font = UIFont.systemFont(ofSize: 12)
        addressLabel.textColor = .darkGray
        addressLabel.textAlignment = .center
        addressLabel.numberOfLines = 2

        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(loadingIndicator)

        setupConstraints()
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(80)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.leading.trailing.bottom.equalToSuperview().inset(10)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(imageView)
        }
    }

    func configure(with place: Place) {
        self.place = place
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address ?? "주소 없음"

        if let photoReference = place.photos?.first?.photoReference {
            loadingIndicator.startAnimating()
            placeSearchViewModel.fetchPlacePhoto(reference: photoReference, maxWidth: 400) { [weak self] image in
                guard let self = self else { return }
                self.loadingIndicator.stopAnimating()
                if let image = image {
                    self.imageView.image = image
                } else {
                    self.imageView.image = UIImage(named: "defaultImage")
                }
            }
        } else {
            imageView.image = UIImage(named: "defaultImage")
        }
    }

    @objc private func handleTap() {
        guard let place = place else { return }
        delegate?.didTapFacilityCell(self, place: place)
    }
}
