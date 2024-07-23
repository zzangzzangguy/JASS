import UIKit
import GooglePlaces
import Then
import SnapKit
import RxSwift
import RxCocoa

class GymDetailViewController: UIViewController, UIScrollViewDelegate {
    weak var coordinator: Coordinator?
    var viewModel: GymDetailViewModel
    private let disposeBag = DisposeBag()
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

    private let reviewCountLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .black
        $0.isUserInteractionEnabled = true
    }

    private let ratingLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .black
    }

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .black
        $0.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    private let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.tintColor = .gray
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: animated)
        coordinator?.popViewController()
    }

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
        let detailsStackView = UIStackView(arrangedSubviews: [nameLabel, addressLabel, phoneLabel, openingHoursLabel, reviewCountLabel, ratingLabel, favoriteButton])
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
        reviewCountLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        ratingLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        favoriteButton.setContentHuggingPriority(.defaultLow, for: .vertical)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapReviewCountLabel))
        reviewCountLabel.addGestureRecognizer(tapGesture)
    }

    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.width.height.equalTo(44)
        }
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func bindViewModel() {
        let input = GymDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            favoriteButtonTapped: favoriteButton.rx.tap.asObservable(),
            loadImages: Observable.just(())
        )

        let output = viewModel.transform(input: input)

        output.placeDetails
            .drive(onNext: { [weak self] place in
                self?.populateData(with: place)
            })
            .disposed(by: disposeBag)

        output.isLoading
            .drive(loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        output.favoriteStatus
            .drive(onNext: { [weak self] isFavorite in
                self?.updateFavoriteButton(isFavorite: isFavorite, showToast: true)
            })
            .disposed(by: disposeBag)

        output.images
            .drive(onNext: { [weak self] images in
                self?.images = images
                self?.setupImageViews()
            })
            .disposed(by: disposeBag)
    }

    private func populateData(with place: Place?) {
        guard let place = place else { return }
        nameLabel.text = place.name
        addressLabel.text = place.formatted_address ?? "등록된 주소 정보가 없습니다"
        phoneLabel.text = "Phone: \(place.phoneNumber ?? "등록된 전화번호 정보가 없습니다")"
        openingHoursLabel.text = place.openingHours ?? "등록된 영업시간 정보가 없습니다"
        //        reviewCountLabel.text = "총 \(place.userRatingsTotal ?? 0)개의 리뷰"
        ratingLabel.text = "평점: \(place.rating ?? 0.0)"
        let reviewCount = place.reviews?.count ?? 0
        reviewCountLabel.text = "총 \(reviewCount)개의 리뷰"
    }

    private func setupImageViews() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        if images.isEmpty {
            let noPhotoLabel = UILabel()
            noPhotoLabel.text = "등록된 사진이 없습니다"
            noPhotoLabel.textAlignment = .center
            scrollView.addSubview(noPhotoLabel)
            noPhotoLabel.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.width.equalTo(scrollView)
            }
            pageControl.isHidden = true
        } else {
            for (index, image) in images.enumerated() {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                scrollView.addSubview(imageView)
                imageView.snp.makeConstraints {
                    $0.leading.equalToSuperview().offset(CGFloat(index) * scrollView.frame.width)
                    $0.width.equalTo(scrollView.snp.width)
                    $0.height.equalTo(scrollView.snp.height)
                    $0.top.equalToSuperview()
                }
            }
            scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(images.count), height: scrollView.frame.height)
            pageControl.numberOfPages = images.count
            pageControl.isHidden = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }

    @objc private func backButtonTapped() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.popViewController(animated: true)
    }

    private func updateFavoriteButton(isFavorite: Bool, showToast: Bool) {
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

    @objc private func didTapReviewCountLabel() {
        let reviewViewController = ReviewViewController(placeID: viewModel.placeID)
        navigationController?.pushViewController(reviewViewController, animated: true)
    }
}
