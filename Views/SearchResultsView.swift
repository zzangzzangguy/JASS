import UIKit
import SnapKit
import Then
import SDWebImage

class SearchResultsView: UIView {
    private let tableView = UITableView().then {
        $0.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        $0.rowHeight = 100
    }

    var viewModel: PlaceSearchViewModel?
    weak var delegate: SearchResultsViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
    }

    func update(with places: [Place]) {
        viewModel?.searchResults = places
        tableView.reloadData()
    }
}

extension SearchResultsView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.searchResults.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        if let place = viewModel?.searchResults[indexPath.row] {
            cell.configure(with: place)
            cell.delegate = self
        }
        return cell
    }
}

extension SearchResultsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = viewModel?.searchResults[indexPath.row] else { return }
        delegate?.didSelectPlace(place)
    }
}

extension SearchResultsView: SearchResultCellDelegate {
    func didTapFavoriteButton(for cell: SearchResultCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let place = viewModel?.searchResults[indexPath.row] else { return }
        delegate?.didTapFavoriteButton(for: place)
    }
}

protocol SearchResultsViewDelegate: AnyObject {
    func didSelectPlace(_ place: Place)
    func didTapFavoriteButton(for place: Place)
}

protocol SearchResultCellDelegate: AnyObject {
    func didTapFavoriteButton(for cell: SearchResultCell)
}

class SearchResultCell: UITableViewCell {
    private let placeImageView = UIImageView()
    private let nameLabel = UILabel()
    private let distanceLabel = UILabel()
    private let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
    }

    weak var delegate: SearchResultCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(placeImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(distanceLabel)
        contentView.addSubview(favoriteButton)

        placeImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.leading.equalToSuperview().inset(20)
            $0.width.height.equalTo(80)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(placeImageView.snp.top)
            $0.leading.equalTo(placeImageView.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(20)
        }

        distanceLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(5)
            $0.leading.equalTo(nameLabel.snp.leading)
        }

        favoriteButton.snp.makeConstraints {
            $0.centerY.equalTo(placeImageView.snp.centerY)
            $0.trailing.equalToSuperview().inset(20)
        }

        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }

    func configure(with place: Place) {
        // 장소 이미지를 비동기로 로드
        if let imageURL = URL(string: place.imageURL) {
            placeImageView.sd_setImage(with: imageURL, completed: nil)
        }

        // 장소 이름 설정
        nameLabel.text = place.name

        // 현재 위치와 장소 간의 거리 계산
        if let currentLocation = LocationManager.shared.currentLocation {
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = currentLocation.distance(from: placeLocation)
            distanceLabel.text = String(format: "%.1f km", distance / 1000)
        } else {
            distanceLabel.text = "거리 정보 없음"
        }

        // 사용자의 즐겨찾기 상태에 따라 즐겨찾기 버튼 색상 설정
        let isFavorite = FavoritesManager.shared.isFavorite(place)
        favoriteButton.tintColor = isFavorite ? .red : .gray
    }

    @objc private func favoriteButtonTapped() {
        delegate?.didTapFavoriteButton(for: self)
    }
}

// 테스트 코드 (SearchResultsViewTests.swift)
import XCTest
@testable import YourAppModule

class SearchResultsViewTests: XCTestCase {
    var searchResultsView: SearchResultsView!
    var viewModel: PlaceSearchViewModel!

    override func setUp() {
        super.setUp()
        searchResultsView = SearchResultsView()
        viewModel = PlaceSearchViewModel()
        searchResultsView.viewModel = viewModel
    }

    func testUpdate_withPlaces_shouldReloadTableView() {
        // Given
        let place1 = Place(name: "Place 1", imageURL: "", latitude: 0, longitude: 0)
        let place2 = Place(name: "Place 2", imageURL: "", latitude: 0, longitude: 0)
        let places = [place1, place2]

        // When
        searchResultsView.update(with: places)

        // Then
        XCTAssertEqual(searchResultsView.tableView.numberOfRows(inSection: 0), 2)
    }

    func testDidSelectPlace_shouldCallDelegate() {
        // Given
        let place = Place(name: "Selected Place", imageURL: "", latitude: 0, longitude: 0)
        viewModel.searchResults = [place]
        let delegateMock = SearchResultsViewDelegateMock()
        searchResultsView.delegate = delegateMock

        // When
        searchResultsView.tableView(searchResultsView.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertTrue(delegateMock.didSelectPlaceCalled)
        XCTAssertEqual(delegateMock.selectedPlace, place)
    }
}

class SearchResultsViewDelegateMock: SearchResultsViewDelegate {
    var didSelectPlaceCalled = false
    var selectedPlace: Place?

    func didSelectPlace(_ place: Place) {
        didSelectPlaceCalled = true
        selectedPlace = place
    }

    func didTapFavoriteButton(for place: Place) {}
}
