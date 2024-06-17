import UIKit
import SnapKit

class NearbyFacilitiesTableViewCell: UITableViewCell {
    static let id = "NearbyFacilitiesTableViewCell"

    private let collectionView: UICollectionView
    private var places: [Place] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 150, height: 180)
        layout.minimumLineSpacing = 10
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FacilityCollectionViewCell.self, forCellWithReuseIdentifier: FacilityCollectionViewCell.identifier)
        collectionView.backgroundColor = .clear
    }

    func configure(with places: [Place]) {
        self.places = places
        collectionView.reloadData()
    }

    func setImage(_ image: UIImage, at index: Int) {
        if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FacilityCollectionViewCell {
            cell.setImage(image)
        }
    }
}

extension NearbyFacilitiesTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FacilityCollectionViewCell.identifier, for: indexPath) as? FacilityCollectionViewCell else {
            return UICollectionViewCell()
        }
        let place = places[indexPath.item]
        cell.configure(with: place)
        return cell
    }
}
