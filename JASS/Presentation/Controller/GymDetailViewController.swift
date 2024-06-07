import UIKit
import GooglePlaces
import Then
import SnapKit

class GymDetailViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - Properties
    var gym: Place?
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    var images: [UIImage] = []

    init(place: Place) {
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

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Gym Data: \(String(describing: gym))")

        setupUI()
        fetchPlaceDetails()
        fetchPlacePhotos()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        setupScrollView()
        setupPageControl()
        setupDetails()
        setupLoadingIndicator()
    }

    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
        }
    }

    private func setupPageControl() {
        pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.red
        view.addSubview(pageControl)

        pageControl.snp.makeConstraints {
            $0.top.equalTo(scrollView.snp.bottom)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
        }
    }

    private func setupDetails() {
        let detailsStackView = UIStackView(arrangedSubviews: [nameLabel, addressLabel, phoneLabel, openingHoursLabel, favoriteButton])
        detailsStackView.axis = .vertical
        detailsStackView.spacing = 10
        detailsStackView.alignment = .leading

        view.addSubview(detailsStackView)
        detailsStackView.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(0)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)

        }
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        phoneLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        openingHoursLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        favoriteButton.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
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

        updateFavoriteButton(showToast: false) // 초기 로드 시 토스트 메시지를 표시하지 않음
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

            guard let photos = photoMetadataList?.results, !photos.isEmpty else {
                self.showNoImageIcon()
                return
            }

            self.pageControl.numberOfPages = photos.count
            self.pageControl.currentPage = 0

            for photoMetadata in photos {
                self.loadImageForMetadata(photoMetadata: photoMetadata)
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

        scrollView.addSubview(stackView)

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
                    self.addImageToScrollView(photo: photo)
                }
            }
        })
    }

    private func addImageToScrollView(photo: UIImage) {
        let imageView = UIImageView(image: photo)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        let xPosition = self.scrollView.bounds.width * CGFloat(images.count)
        imageView.frame = CGRect(x: xPosition, y: 0, width: self.scrollView.bounds.width, height: self.scrollView.bounds.height)

        scrollView.addSubview(imageView)
        scrollView.contentSize.width = self.scrollView.bounds.width * CGFloat(images.count + 1)
        images.append(photo)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / view.bounds.width)
        pageControl.currentPage = Int(pageIndex)
    }

    @objc private func toggleFavorite() {
        guard let gym = gym else { return }
        FavoritesManager.shared.toggleFavorite(place: gym)
        updateFavoriteButton(showToast: true)
    }

    private func updateFavoriteButton(showToast: Bool) {
        guard let gym = gym else { return }
        let isFavorite = FavoritesManager.shared.isFavorite(placeID: gym.place_id)
        let heartImage = isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        let tintColor: UIColor = isFavorite ? .red : .gray
        favoriteButton.setImage(heartImage, for: .normal)
        favoriteButton.tintColor = tintColor

        if showToast {
            showToastForFavorite(isFavorite: isFavorite)
        }
    }

    private func showToastForFavorite(isFavorite: Bool) {
        let message = isFavorite ? "즐겨찾기에 추가되었습니다" : "즐겨찾기에서 제거되었습니다"
        let toastLabel = UILabel().then {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 14)
            $0.text = message
            $0.alpha = 1.0
            $0.layer.cornerRadius = 10
            $0.clipsToBounds = true
        }

        view.addSubview(toastLabel)
        toastLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-100)
            $0.width.equalTo(200)
            $0.height.equalTo(35)
        }

        UIView.animate(withDuration: 2.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
}
