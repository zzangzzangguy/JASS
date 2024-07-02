import UIKit
import GoogleMaps
import GooglePlaces
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupGoogleMapsAndPlaces()
        setupRealm()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    // MARK: - Private Methods

    private func setupGoogleMapsAndPlaces() {
        if let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
            print("Google Maps API Key: \(apiKey)")
            GMSServices.provideAPIKey(apiKey)
            GMSPlacesClient.provideAPIKey(apiKey)
        } else {
            fatalError("API 키 연결에 실패했습니다.")
        }
    }

    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: FavoritePlace.className()) { oldObject, newObject in
                        // 필요한 마이그레이션 로직 추가
                    }
                }
            })

        // Realm 설정 적용
        Realm.Configuration.defaultConfiguration = config

        // Realm 초기화
        do {
            _ = try Realm()
        } catch {
            print("Realm 초기화 실패: \(error)")
        }
    }
}
