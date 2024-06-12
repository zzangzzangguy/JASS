//
//  AppDelegate.swift
//  JASS
//
//  Created by 김기현 on 12/3/23.
//

import UIKit
import GoogleMaps
import GooglePlaces
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
            GMSServices.provideAPIKey(apiKey)
            GMSPlacesClient.provideAPIKey(apiKey)

        } else {
            fatalError("API 키 연결에 실패했습니다.")
        }
        let config = Realm.Configuration(
                   schemaVersion: 2, // 새로운 스키마 버전 (기존 버전보다 높은 값으로 설정)
                   migrationBlock: { migration, oldSchemaVersion in
                       if oldSchemaVersion < 1 {
                           // 이전 스키마 버전이 1보다 낮은 경우 실행할 마이그레이션 코드
                           migration.enumerateObjects(ofType: FavoritePlace.className()) { oldObject, newObject in
                               // 'name' 속성을 필수에서 선택적(optional)으로 변경
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

               return true
           }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

