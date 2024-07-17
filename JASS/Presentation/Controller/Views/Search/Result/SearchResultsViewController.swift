import UIKit
import SnapKit
import Then
import Kingfisher
import CoreLocation
import Toast
import RxSwift
import RxCocoa

protocol SearchResultsViewDelegate: AnyObject {
    func didSelectPlace(_ place: Place)
}

class SearchResultsViewController: UIViewController {

    // MARK: - Properties

    private let searchBar = UISearchBar().then {
        $0.backgroundImage = UIImage()
        $0.placeholder = "검색어를 입력하세요"
        // 기존 코드
        // $0.searchBarStyle = .minimal
        // $0.layer.borderWidth = 1
        // $0.layer.borderColor = UIColor.lightGray.cgColor
        // $0.layer.cornerRadius = 10
        // $0.clipsToBounds = true

        // 수정된 코드
        $0.searchTextField.backgroundColor = .white
        $0.searchTextField.layer.cornerRadius = 18
        $0.searchTextField.layer.masksToBounds = true
        $0.searchTextField.leftView = nil
        if let searchIcon = $0.searchTextField.leftView as? UIImageView {
            searchIcon.image = UIImage(systemName: "magnifyingglass")
        }
    }

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .black
    }

    private let searchButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        $0.tintColor = .black
    }

    private let filterButton = UIButton(type: .system).then {
        $0.setTitle("필터", for: .normal)
        $0.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.tintColor = .black
        $0.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 15
    }

    private lazy var tableView = UITableView().then {
        $0.delegate = self
        $0.dataSource = self
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 120
        $0.keyboardDismissMode = .onDrag
        $0.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseIdentifier)
    }

    var selectedCategories: Set<String> = []
    var currentLocation: CLLocationCoordinate2D?
    private let loadNextPageSubject = PublishSubject<Void>()
    private let disposeBag = DisposeBag()
    private let defaultCategory = "헬스,필라테스,크로스핏,복싱,수영,골프,클라이밍"

    var searchQuery: String? {
        didSet {
            searchBar.text = searchQuery
        }
    }
    var recentPlacesViewModel: RecentPlacesViewModel?
    var placeSearchViewModel: PlaceSearchViewModel?
    var viewModel: SearchResultsViewModel?
    weak var delegate: SearchResultsViewDelegate?

    // MARK: - Initializer
    init(placeSearchViewModel: PlaceSearchViewModel, recentPlacesViewModel: RecentPlacesViewModel, viewModel: SearchResultsViewModel) {
        self.placeSearchViewModel = placeSearchViewModel
        self.recentPlacesViewModel = recentPlacesViewModel
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        print("DEBUG: placeSearchViewModel 초기화 완료")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupActions()
        setupLocationManager()
        performInitialSearch()

        // 즐겨찾기 변경 이벤트 구독
        FavoritesManager.shared.favoriteChanged
            .subscribe(onNext: { [weak self] placeId in
                self?.updateFavoriteUI(for: placeId)
            })
            .disposed(by: disposeBag)
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
        [backButton, searchBar, searchButton, filterButton, tableView].forEach { view.addSubview($0) }
        setupConstraints()
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.width.height.equalTo(44)
        }

        searchBar.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing).offset(8)
            $0.trailing.equalTo(searchButton.snp.leading).offset(-8)
            $0.centerY.equalTo(backButton)
            // 기존 코드
            // $0.height.equalTo(44)

            // 수정된 코드
            $0.height.equalTo(36)
        }

        searchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(backButton)
            $0.width.height.equalTo(44)
        }

        filterButton.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(16)
            $0.height.equalTo(30)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(filterButton.snp.bottom).offset(10)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func bindViewModel() {
        guard let viewModel = viewModel else { return }

        let input = SearchResultsViewModel.Input(
            viewDidLoad: Observable.just(()),
            searchTrigger: searchBar.rx.text.orEmpty.asObservable(),
            filterTrigger: Observable.just(selectedCategories),
            itemSelected: tableView.rx.itemSelected.map { $0.row }.asObservable(),
            favoriteToggle: Observable.never(),
            currentLocation: .just(self.currentLocation),
            loadNextPage: loadNextPageSubject.asObservable()


        )

        let output = viewModel.transform(input: input)

        output.isLoading
            .drive(onNext: { isLoading in
                print("DEBUG: isLoading - \(isLoading)")
            })
            .disposed(by: disposeBag)

        output.searchResults
            .drive(onNext: { [weak self] (places: [Place]) in
                print("DEBUG: 검색 결과 업데이트 - 총 \(places.count)개 장소")
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        output.error
            .drive(onNext: { [weak self] (errorMessage: String) in
                guard let self = self, !errorMessage.isEmpty else { return }
                self.showToast(errorMessage)
            })
            .disposed(by: disposeBag)

        output.favoriteUpdated
            .drive(onNext: { [weak self] (place: Place) in
                guard let self = self else { return }
                self.updateFavoriteButton(for: place)
            })
            .disposed(by: disposeBag)
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        searchBar.delegate = self
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
    }

    private func setupLocationManager() {
        LocationManager.shared.onLocationUpdate = { [weak self] location in
            self?.currentLocation = location
        }
        LocationManager.shared.startUpdatingLocation()
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func searchButtonTapped() {
        performSearch()
    }

    @objc private func filterButtonTapped() {
        let filterVC = FilterViewController()
        filterVC.delegate = self
        filterVC.selectedCategories = selectedCategories
        present(filterVC, animated: true, completion: nil)
    }

    private func performSearch(with categories: [String]? = nil) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        let categoriesToUse = categories ?? Array(selectedCategories)
        let category = categoriesToUse.isEmpty ? defaultCategory : categoriesToUse.joined(separator: ",")

        LoadingIndicatorManager.shared.show(in: view)

        guard let placeSearchViewModel = placeSearchViewModel else {
            showToast("검색 기능을 초기화하는 데 문제가 발생했습니다.")
            LoadingIndicatorManager.shared.hide()
            return
        }

        placeSearchViewModel.searchPlace(input: query, filters: selectedCategories, currentLocation: self.currentLocation)
            .flatMap { [weak self] places -> Observable<[Place]> in
                guard let self = self, let currentLocation = self.currentLocation else {
                    return Observable.just(places)
                }
                return placeSearchViewModel.calculateDistances(for: places, from: currentLocation)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] places in
                guard let self = self else { return }
                LoadingIndicatorManager.shared.hide()
                self.viewModel?.loadSearchResults(with: places)
                self.tableView.reloadData()
                if places.isEmpty {
                    self.showToast("검색 결과가 없습니다.")
                }
                print("DEBUG: 검색 완료 - 쿼리: \(query), 카테고리: \(category), 결과 수: \(places.count)")
            }, onError: { [weak self] error in
                self?.showToast("검색 중 오류가 발생했습니다: \(error.localizedDescription)")
                LoadingIndicatorManager.shared.hide()
                print("DEBUG: 검색 오류 - \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    private func performInitialSearch() {
        guard let query = searchQuery else { return }
        performSearch(with: [defaultCategory])
    }

    private func showToast(_ message: String) {
        view.makeToast(message)
    }

    private func updateFavoriteButton(for place: Place) {
        guard let index = viewModel?.searchResultsRelay.value.firstIndex(where: { $0.place_id == place.place_id }),
              let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SearchResultCell else { return }

        let isFavorite = viewModel?.favoritesManager.isFavorite(placeID: place.place_id ?? "") ?? false
        cell.updateFavoriteButton(isFavorite: isFavorite)
    }

    private func updateFavoriteUI(for placeId: String) {  // 추가된 메서드
        guard let index = viewModel?.searchResultsRelay.value.firstIndex(where: { $0.place_id == placeId }),
              let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SearchResultCell else { return }

        let isFavorite = FavoritesManager.shared.isFavorite(placeID: placeId)
        cell.updateFavoriteButton(isFavorite: isFavorite)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension SearchResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.searchResultsRelay.value.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.reuseIdentifier, for: indexPath) as? SearchResultCell,
              let place = viewModel?.searchResultsRelay.value[indexPath.row] else {
            return UITableViewCell()
        }

        print("DEBUG: cellForRowAt - 장소: \(place.name), 거리: \(place.distanceText ?? "없음")")
        cell.configure(with: place, currentLocation: currentLocation)
        cell.delegate = self

        placeSearchViewModel?.fetchPlaceDetails(placeID: place.place_id) { [weak cell] detailedPlace in
            DispatchQueue.main.async {
                if let detailedPlace = detailedPlace {
                    var updatedPlace = detailedPlace
                    updatedPlace.distanceText = place.distanceText
                    cell?.configure(with: updatedPlace, currentLocation: self.currentLocation)
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = viewModel?.searchResultsRelay.value[indexPath.row],
              let placeSearchViewModel = placeSearchViewModel else { return }
        recentPlacesViewModel?.addRecentPlace(place)
        delegate?.didSelectPlace(place)
        let gymDetailVC = GymDetailViewController(viewModel: GymDetailViewModel(placeID: place.place_id, placeSearchViewModel: placeSearchViewModel))
        navigationController?.pushViewController(gymDetailVC, animated: true)
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let totalCount = viewModel?.searchResultsRelay.value.count else { return }
        if indexPath.row == totalCount - 1 {
            print("DEBUG: 마지막 셀 도달, 다음 페이지 로드 시도")
            loadNextPageSubject.onNext(())
        }
    }


}

// MARK: - SearchResultCellDelegate

extension SearchResultsViewController: SearchResultCellDelegate {

    func didTapFavoriteButton(for cell: SearchResultCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let place = viewModel?.searchResultsRelay.value[indexPath.row] else { return }

        viewModel?.updateFavoriteStatus(for: place)

        let isFavorite = viewModel?.favoritesManager.isFavorite(placeID: place.place_id ?? "") ?? false
        cell.updateFavoriteButton(isFavorite: isFavorite)

        let message = isFavorite ? "즐겨찾기에 추가되었습니다." : "즐겨찾기에서 제거되었습니다."
        showToast(message)
    }
}

// MARK: - UISearchBarDelegate

extension SearchResultsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
}

// MARK: - FilterViewDelegate

extension SearchResultsViewController: FilterViewDelegate {
    func filterViewDidCancel(_ filterView: FilterViewController) {
        dismiss(animated: true, completion: nil)
    }

    func filterView(_ filterView: FilterViewController, didSelectCategories categories: Set<String>) {
        selectedCategories = categories.isEmpty ? [defaultCategory] : categories
        performSearch(with: Array(selectedCategories))
    }
}
