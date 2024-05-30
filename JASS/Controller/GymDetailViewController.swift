import UIKit
import GooglePlaces
import Then
import SnapKit

class GymDetailViewController: UIViewController {

    // MARK: - Properties
    var gym: Place?
    var scrollView: UIScrollView!
    var contentView: UIView!
    var pageControl: UIPageControl!
    var images: [UIImage] = []

    init(place: Place) { // 초기화 메소드 추가
        gym = place
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let nameLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .black
        $0.numberOfLines = 0
    }

    private let addressLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .gray
        $0.numberOfLines = 0
    }

    private let phoneLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .gray
    }

    private let openingHoursLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .gray
        $0.numberOfLines = 0
    }

    private let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.tintColor = .gray
        $0.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
    }

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Gym Data: \(String(describing: gym))")

        setupUI()
        fetchPlaceDetails() // 장소 세부정보 가져오기
        fetchPlacePhotos()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        setupScrollView()
        setupImageView()
        setupFavoriteButton()
        setupDetails()
        setupLoadingIndicator()
        showNoImageIcon()
    }

    private func setupScrollView() {
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
    }

    private func setupImageView() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
        }
    }

    private func setupFavoriteButton() {
        contentView.addSubview(favoriteButton)
        favoriteButton.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.top).offset(10)
            $0.trailing.equalTo(imageView.snp.trailing).offset(-10)
        }
    }

    private func setupDetails() {
        let detailsStackView = UIStackView(arrangedSubviews: [nameLabel, addressLabel, phoneLabel, openingHoursLabel])
        detailsStackView.axis = .vertical
        detailsStackView.spacing = 10
        detailsStackView.alignment = .leading

        contentView.addSubview(detailsStackView)
        detailsStackView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(contentView).inset(20)
            $0.bottom.equalToSuperview().offset(-20) // 마지막에 스크롤뷰의 끝까지 공간을 확보합니다.
        }
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        phoneLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        openingHoursLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func setupLoadingIndicator() {
        contentView.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(imageView)
        }
    }

    private func fetchPlaceDetails() {
        guard let gym = gym else { return }

        let placeID = gym.place_id
        let placeFields: GMSPlaceField = [.name, .formattedAddress, .phoneNumber, .website, .openingHours, .coordinate]

        GMSPlacesClient.shared().fetchPlace(fromPlaceID: placeID, placeFields: placeFields, sessionToken: nil) { [weak self] (place, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                return
            }

            if let place = place {
                self.populateData(with: place)
            }
        }
    }

    private func populateData(with place: GMSPlace) {
        nameLabel.text = place.name

        if let address = place.formattedAddress {
            addressLabel.text = address
        } else {
            addressLabel.text = "등록된 주소 정보가 없습니다"
        }

        if let phone = place.phoneNumber {
            phoneLabel.text = "Phone: \(phone)"
        } else {
            phoneLabel.text = "등록된 전화번호 정보가 없습니다"
        }

        if let openingHours = place.openingHours, let weekdayText = openingHours.weekdayText {
            openingHoursLabel.text = "Hours: \(weekdayText.joined(separator: "\n"))"
        } else {
            openingHoursLabel.text = "등록된 영업시간 정보가 없습니다"
        }

        updateFavoriteButton()
    }

    private func fetchPlacePhotos() {
        guard let gym = gym else { return }

        loadingIndicator.startAnimating()

        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: gym.place_id) { [weak self] (photoMetadataList, error) in
            guard let self = self else { return }

            self.loadingIndicator.stopAnimating()

            if let error = error {
                print("Error fetching photos: \(error.localizedDescription)")
                self.showNoImageIcon()
                return
            }

            guard let photos = photoMetadataList?.results else {
                self.showNoImageIcon()
                return
            }

            if let firstPhotoMetadata = photos.first {
                self.loadImageForMetadata(photoMetadata: firstPhotoMetadata)
            }
        }
    }

    private func showNoImageIcon() {
        let stackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 8
            $0.alignment = .center

            let noImageIcon = UIImage(systemName: "photo")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
            let imageView = UIImageView(image: noImageIcon).then {
                $0.contentMode = .scaleAspectFit
            }

            let label = UILabel().then {
                $0.text = "등록된 사진이 없습니다"
                $0.textColor = .gray
                $0.textAlignment = .center
            }

            $0.addArrangedSubview(imageView)
            $0.addArrangedSubview(label)
        }

        contentView.addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, callback: { [weak self] (photo, error) -> Void in
            guard let self = self else { return }

            if let error = error {
                print("Error loading photo metadata: \(error.localizedDescription)")
                return
            }

            if let photo = photo {
                DispatchQueue.main.async {
                    self.imageView.image = photo
                }
            }
        })
    }

    @objc private func toggleFavorite() {
        guard let gym = gym else { return }
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: gym.place_id)

        if isFavorite {
            FavoritesManager.shared.removeFavorite(place: gym)
            showToast(message: "즐겨찾기에서 제거되었습니다.")
        } else {
            FavoritesManager.shared.addFavorite(place: gym)
            showToast(message: "즐겨찾기에 추가되었습니다.")
        }

        updateFavoriteButton()
    }

    private func updateFavoriteButton() {
        guard let gym = gym else { return }
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: gym.place_id)
        let heartImage = isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        let tintColor: UIColor = isFavorite ? .red : .gray
        favoriteButton.setImage(heartImage, for: .normal)
        favoriteButton.tintColor = tintColor
    }

    private func showToast(message: String) {
        let toastLabel = UILabel().then {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            $0.textColor = UIColor.white
            $0.font = UIFont.systemFont(ofSize: 14.0)
            $0.textAlignment = .center
            $0.text = message
            $0.alpha = 1.0
            $0.layer.cornerRadius = 10
            $0.clipsToBounds = true
        }

        self.view.addSubview(toastLabel)
        toastLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(50)
            $0.bottom.equalToSuperview().inset(100)
            $0.height.equalTo(35)
        }

        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
}
