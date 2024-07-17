import UIKit
import SnapKit

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
