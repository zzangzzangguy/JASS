import UIKit
import CoreLocation
import SnapKit

class MainViewController: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate {
    let locationManager = CLLocationManager()
    let searchBar = UISearchBar()
    let currentLocationLabel = UILabel()
    let findOnMapButton = UIButton()
    let headerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupLocationManager()
        setupHeaderView()
        setupSearchBar()
        setupFindOnMapButton()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func setupHeaderView() {
        headerView.backgroundColor = .white
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        headerView.addSubview(currentLocationLabel)
        currentLocationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
    }
    
    func setupSearchBar() {
        searchBar.placeholder = "어떤 운동을 찾고 계신가요?"
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    func setupFindOnMapButton() {
        findOnMapButton.setTitle("지도에서 찾기", for: .normal)
        findOnMapButton.backgroundColor = .systemBlue
        findOnMapButton.setTitleColor(.white, for: .normal)
        findOnMapButton.layer.cornerRadius = 8
        findOnMapButton.addTarget(self, action: #selector(findOnMapButtonTapped), for: .touchUpInside)
        self.view.addSubview(findOnMapButton)
        findOnMapButton.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    @objc func findOnMapButtonTapped() {
        let mapVC = MapViewController()
        self.navigationController?.pushViewController(mapVC, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let error = error {
                print("Reverse geocode error: \(error)")
                self.currentLocationLabel.text = "위치를 가져올 수 없습니다."
                return
            }
            if let placemark = placemarks?.first {
                self.currentLocationLabel.text = "\(placemark.locality ?? "") \(placemark.subLocality ?? "")"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let searchVC = SearchViewController()
        searchVC.modalPresentationStyle = .overFullScreen
        self.present(searchVC, animated: true, completion: nil)
    }
}
