import UIKit
import SnapKit
import SDWebImage

class ReviewTableViewCell: UITableViewCell {
    static let identifier = "ReviewTableViewCell"

    let authorLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
    }

    let dateLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .gray
    }

    let ratingLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .orange
    }

    let reviewTextLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .black
        $0.numberOfLines = 0
    }

    let reviewImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(authorLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(reviewTextLabel)
        contentView.addSubview(reviewImageView)

        authorLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(authorLabel.snp.bottom).offset(8)
            $0.leading.equalTo(authorLabel)
        }

        ratingLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel)
            $0.leading.equalTo(dateLabel.snp.trailing).offset(8)
        }

        reviewImageView.snp.makeConstraints {
            $0.top.equalTo(ratingLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.width.height.equalTo(100)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }

        reviewTextLabel.snp.makeConstraints {
            $0.top.equalTo(reviewImageView.snp.top)
            $0.leading.equalTo(reviewImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    func configure(with review: Review) {
        authorLabel.text = review.authorName
        dateLabel.text = formatDate(timestamp: review.time)
        ratingLabel.text = String(repeating: "★", count: review.rating ?? 0)
        reviewTextLabel.text = review.text
        if let photoUrl = review.profilePhotoUrl, let url = URL(string: photoUrl) {
            reviewImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "sample_image"))
        } else {
            reviewImageView.image = UIImage(named: "sample_image")
        }
    }

    private func formatDate(timestamp: Int?) -> String? {
        guard let timestamp = timestamp else { return nil }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        return dateFormatter.string(from: date)
    }
}
