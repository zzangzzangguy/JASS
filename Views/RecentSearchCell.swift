import UIKit

protocol RecentSearchCellDelegate: AnyObject {
    func didDeleteRecentSearch(query: String)
}

class RecentSearchCell: UITableViewCell {
    static let reuseIdentifier = "RecentSearchCell"

    let queryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .gray
        return button
    }()

    weak var delegate: RecentSearchCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(queryLabel)
        contentView.addSubview(deleteButton)

        queryLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        deleteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    func configure(with query: String) {
        queryLabel.text = query
    }

    @objc func deleteButtonTapped() {
        guard let query = queryLabel.text else { return }
        delegate?.didDeleteRecentSearch(query: query)
    }
}
