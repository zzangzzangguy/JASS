import UIKit
import SnapKit
import Then

protocol FilterViewDelegate: AnyObject {
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: Set<String>)
    func filterViewDidCancel(_ filterView: FilterViewController)
}

class FilterViewController: UIViewController {
    private var categories = ["헬스", "필라테스", "복싱", "크로스핏", "골프", "수영", "클라이밍"]
    var selectedCategories: Set<String> = []

    weak var delegate: FilterViewDelegate?

    private let applyButton = UIButton().then {
        $0.setTitle("적용하기", for: .normal)
        $0.backgroundColor = .systemBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 10
    }

    private let cancelButton = UIButton().then {
        $0.setTitle("취소", for: .normal)
        $0.backgroundColor = .lightGray
        $0.setTitleColor(.black, for: .normal)
        $0.layer.cornerRadius = 10
    }

    private let allCategoriesButton = UIButton().then {
        $0.setTitle("전체 선택", for: .normal)
        $0.setTitleColor(.blue, for: .normal)
    }

    private var isAllSelected = false {
        didSet {
            allCategoriesButton.setTitle(isAllSelected ? "전체 해제" : "전체 선택", for: .normal)
        }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: FilterCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setupActions()
    }

    private func setupViews() {
        view.addSubview(allCategoriesButton)
        view.addSubview(collectionView)
        view.addSubview(applyButton)
        view.addSubview(cancelButton)

        allCategoriesButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.right.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(allCategoriesButton.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(applyButton.snp.top).offset(-10)
        }

        applyButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(view.snp.centerX).offset(-5)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.height.equalTo(50)
        }

        cancelButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.left.equalTo(view.snp.centerX).offset(5)
            make.bottom.equalTo(applyButton.snp.bottom)
            make.height.equalTo(50)
        }
    }

    private func setupActions() {
        applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        allCategoriesButton.addTarget(self, action: #selector(allCategoriesButtonTapped), for: .touchUpInside)
    }

    @objc private func applyButtonTapped() {
        if selectedCategories.isEmpty {
            selectedCategories = Set(categories)
        }
        delegate?.filterView(self, didSelectCategories: selectedCategories)
        dismiss(animated: true, completion: nil)
    }

    @objc private func cancelButtonTapped() {
        delegate?.filterViewDidCancel(self)
        dismiss(animated: true, completion: nil)
    }

    @objc private func allCategoriesButtonTapped() {
        isAllSelected.toggle()
        if isAllSelected {
            selectedCategories = Set(categories)
        } else {
            selectedCategories.removeAll()
        }
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension FilterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCollectionViewCell.identifier, for: indexPath) as? FilterCollectionViewCell else {
            fatalError("Unable to dequeue FilterCollectionViewCell")
        }
        let category = categories[indexPath.item]
        cell.configure(with: category)
        cell.isChecked = selectedCategories.contains(category)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FilterViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        isAllSelected = selectedCategories.count == categories.count
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 2
        let spacing: CGFloat = 10
        let totalSpacing: CGFloat = (2 * spacing) + ((numberOfColumns - 1) * spacing)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: 50)
    }
}
