import UIKit
import SnapKit
import GooglePlaces

protocol FacilityCollectionViewCellDelegate: AnyObject {
    func didTapFacilityCell(_ cell: FacilityCollectionViewCell, place: Place)
}

final class FacilityCollectionViewCell: UICollectionViewCell {
    static let identifier = "FacilityCollectionViewCell"
    weak var delegate: FacilityCollectionViewCellDelegate?
    private var place: Place?
    private var photoMetadata: GMSPlacePhotoMetadata?

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
        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(10)
            $0.height.equalTo(80)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(5)
            $0.leading.trailing.equalToSuperview().inset(10)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(5)
            $0.leading.trailing.bottom.equalToSuperview().inset(10)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(imageView)
        }
    }

    func configure(with place: Place) {
        self.place = place
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address ?? "주소 없음"
        imageView.image = nil

        loadingIndicator.startAnimating()

        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: place.place_id) { [weak self] (photoMetadataList, error) in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()

            if let error = error {
                print("사진 메타데이터 로드 오류발생: \(error.localizedDescription)")
                self.imageView.image = UIImage(named: "defaultImage")
                return
            }

            guard let photos = photoMetadataList?.results, let firstPhoto = photos.first else {
                print("사진 메타데이터 없음")
                self.imageView.image = UIImage(named: "defaultImage")
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
                if self.photoMetadata == nil {
                    print("사진 로드 오류발생: \(error.localizedDescription)")
                }
                self.imageView.image = UIImage(named: "defaultImage")
                return
            }

            if let photo = photo {
                self.imageView.image = photo
                print("이미지 로드 성공 - Place: \(String(describing: self.place?.name))")
            } else {
                self.imageView.image = UIImage(named: "defaultImage")
                print("이미지 로드 실패, 디폴트 이미지 사용 - Place: \(String(describing: self.place?.name))")
            }
        }
    }


    @objc private func handleTap() {
        guard let place = place else { return }
        delegate?.didTapFacilityCell(self, place: place)
    }
}
