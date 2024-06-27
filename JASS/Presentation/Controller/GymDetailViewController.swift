import UIKit
import GooglePlaces
import Then
import SnapKit

class GymDetailViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - Properties
    var viewModel: GymDetailViewModel
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    var images: [UIImage] = []

    init(viewModel: GymDetailViewModel) {
        self.viewModel = viewModel
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

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .black
        $0.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
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

        setupUI()
        setupBindings()
        viewModel.loadPlaceDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        setupScrollView()
        setupPageControl()
        setupDetails()
        setupLoadingIndicator()
        setupBackButton()
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
            $0.top.equalTo(pageControl.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        phoneLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        openingHoursLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        favoriteButton.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.width.height.equalTo(44)
        }
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setupBindings() {
        viewModel.onPlaceDetailsUpdated = { [weak self] in
            guard let self = self, let place = self.viewModel.placeDetails else { return }
            self.populateData(with: place)
        }
    }

    private func populateData(with place: Place) {
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address ?? "등록된 주소 정보가 없습니다"
        phoneLabel.text = "Phone: \(place.phoneNumber ?? "등록된 전화번호 정보가 없습니다")"
        openingHoursLabel.text = place.openingHours ?? "등록된 영업시간 정보가 없습니다"
        updateFavoriteButton(showToast: false)
        loadImages()  // 이 줄 추가
    }

    private func loadImages() {
        viewModel.loadImages { [weak self] images in
            self?.images = images
            self?.setupImageViews()
        }
    }

    private func setupImageViews() {
        scrollView.subviews.forEach { $0.removeFromSuperview() } // 기존 이미지 뷰 제거

        for (index, image) in images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            scrollView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(CGFloat(index) * scrollView.frame.width)
                make.width.equalTo(scrollView.snp.width)
                make.height.equalTo(scrollView.snp.height)
            }
        }
        scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(images.count), height: scrollView.frame.height)
        pageControl.numberOfPages = images.count
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }

    @objc private func toggleFavorite() {
        guard let gym = viewModel.placeDetails else { return }
        FavoritesManager.shared.toggleFavorite(place: gym)
        updateFavoriteButton(showToast: true)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func updateFavoriteButton(showToast: Bool) {
        guard let gym = viewModel.placeDetails else { return }
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
        view.makeToast(message)
    }
}
