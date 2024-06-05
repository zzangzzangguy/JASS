import UIKit
import SnapKit
import Then

protocol FilterViewDelegate: AnyObject {
    func filterView(_ filterView: FilterViewController, didSelectCategories categories: [String])
    func filterViewDidCancel(_ filterView: FilterViewController)
}

class FilterCollectionViewCell: UICollectionViewCell {
    static let identifier = "FilterCollectionViewCell"

    private lazy var nameLabel: UILabel = {
        
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private lazy var checkboxImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    var isChecked: Bool = false {
        didSet {
            let checkboxImageName = isChecked ? "checkmark.square.fill" : "square"
            checkboxImageView.image = UIImage(systemName: checkboxImageName)
            checkboxImageView.tintColor = isChecked ? .blue : .gray
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(nameLabel)
        addSubview(checkboxImageView)

        nameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }

        checkboxImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with name: String) {
        nameLabel.text = name
    }
}

class FilterViewController: UIViewController {
    private var categories = ["헬스", "필라테스", "복싱", "크로스핏", "골프", "수영", "클라이밍"]
    private var selectedCategories: Set<String> = []

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
        view.addSubview(collectionView)
        view.addSubview(applyButton)
        view.addSubview(cancelButton)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
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
    }

    @objc private func applyButtonTapped() {
        let selectedCategoriesArray = Array(selectedCategories)
        delegate?.filterView(self, didSelectCategories: selectedCategoriesArray)
        dismiss(animated: true, completion: nil)

    }

    @objc private func cancelButtonTapped() {
        delegate?.filterViewDidCancel(self)
    }
}

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

extension FilterViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        collectionView.reloadItems(at: [indexPath])
    }
}

extension FilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 2
        let spacing: CGFloat = 10
        let totalSpacing: CGFloat = (2 * spacing) + ((numberOfColumns - 1) * spacing)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: 50)
    }
}
