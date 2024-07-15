import UIKit
import RxSwift
import SnapKit

class ReviewViewController: UIViewController {
    let placeID: String
    private let apiService = GooglePlacesAPIService()
    private let disposeBag = DisposeBag()
    private var reviews: [Review] = []

    private let reviewCountLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .black
    }

    private let tableView = UITableView().then {
        $0.register(ReviewTableViewCell.self, forCellReuseIdentifier: ReviewTableViewCell.identifier)
        $0.separatorStyle = .none
    }

    init(placeID: String) {
        self.placeID = placeID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchReviews()
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(reviewCountLabel)
        view.addSubview(tableView)

        reviewCountLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(reviewCountLabel.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        tableView.dataSource = self
    }

    private func fetchReviews() {
        apiService.getPlaceDetails(placeID: placeID)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] place in
                self?.reviews = place.reviews ?? []
                self?.reviewCountLabel.text = "총 \(self?.reviews.count ?? 0)개의 리뷰"
                self?.tableView.reloadData()
            }, onError: { error in
                print("Failed to fetch reviews: \(error)")
            })
            .disposed(by: disposeBag)
    }
}

extension ReviewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReviewTableViewCell.identifier, for: indexPath) as? ReviewTableViewCell else {
            return UITableViewCell()
        }

        let review = reviews[indexPath.row]
        cell.configure(with: review)

        return cell
    }
}
