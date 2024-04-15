import UIKit
import Then
import GooglePlaces

class GymDetailViewController: UIViewController {

    // MARK: - Properties
    var gym: Place?

    // MARK: - UI Elements
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateData()
        fetchPlaceDetails()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        [nameLabel, addressLabel, phoneLabel, openingHoursLabel].forEach {
            view.addSubview($0)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        phoneLabel.snp.makeConstraints {
            $0.top.equalTo(addressLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        openingHoursLabel.snp.makeConstraints {
            $0.top.equalTo(phoneLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func populateData() {
        guard let gym = gym else { return }

        nameLabel.text = gym.name
        addressLabel.text = gym.formatted_address
        phoneLabel.text = "전화번호: "
        openingHoursLabel.text = "운영 시간: "
    }

    private func fetchPlaceDetails() {
        guard let gym = gym else { return }

        let placeID = gym.place_id 
        let fields: GMSPlaceField = [.phoneNumber, .openingHours]

        GMSPlacesClient.shared().fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { [weak self] place, error in
            if let error = error {
                print("상세 정보 요청 실패: \(error.localizedDescription)")
                return
            }

            if let place = place {
                self?.populateAdditionalData(place)
            }
        }
    }

    private func populateAdditionalData(_ place: GMSPlace) {
        phoneLabel.text = place.phoneNumber ?? "전화번호 없음"

        if let openingHours = place.openingHours {
            let openingHoursText = openingHours.weekdayText?.joined(separator: "\n") ?? "운영 시간 정보 없음"
            openingHoursLabel.text = openingHoursText
        } else {
            openingHoursLabel.text = "운영 시간 정보 없음"
        }
    }
}
