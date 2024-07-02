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
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.  
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Private Methods

    private func setupGoogleMapsAndPlaces() {
        if let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
            GMSServices.provideAPIKey(apiKey)
            GMSPlacesClient.provideAPIKey(apiKey)
        } else {
            fatalError("API 키 연결에 실패했습니다.")
        }
    }

    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: FavoritePlace.className()) { oldObject, newObject in
                        newObject?["name"] = oldObject?["name"]
                    }
                }
            })

        // Realm 설정 적용
        Realm.Configuration.defaultConfiguration = config

        // Realm 초기화
        do {
            _ = try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error)")
        }
    }
}
