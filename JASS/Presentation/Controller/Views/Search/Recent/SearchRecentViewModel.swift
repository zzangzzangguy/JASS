import RealmSwift
import UIKit

class SearchRecentViewModel {
    static let shared = SearchRecentViewModel()

    let realm: Realm
    var updateRecentSearches: (() -> Void)?
    var handleError: ((Error) -> Void)?

    private var cachedRecentSearches: [String] = []

    var didSelectRecentSearch: ((String) -> Void)?

    init() {
        do {
            realm = try Realm()
        } catch {
            print("Realm 초기화 실패: \(error)")
            handleError?(error)

            fatalError("Realm 초기화 실패")
        }
    }

    func loadRecentSearches() -> [String] {
        if !cachedRecentSearches.isEmpty {
            return cachedRecentSearches
        }

        let recentSearches = Array(realm.objects(SearchHistory.self).sorted(byKeyPath: "date", ascending: false).map { $0.query })
        cachedRecentSearches = recentSearches
        return recentSearches
    }

    func saveSearchHistory(query: String) {
        do {
            try realm.write {
                if let existingHistory = realm.objects(SearchHistory.self).filter("query == %@", query).first {
                    realm.delete(existingHistory)
                }

                if realm.objects(SearchHistory.self).count >= 20 {
                    if let oldestSearch = realm.objects(SearchHistory.self).sorted(byKeyPath: "date", ascending: true).first {
                        realm.delete(oldestSearch)
                    }
                }

                realm.add(SearchHistory(query: query))
            }
            print("검색 이력 저장 완료: \(query)")

            cachedRecentSearches.removeAll(where: { $0 == query })
            cachedRecentSearches.insert(query, at: 0)

            updateRecentSearches?()
        } catch {
            print("Realm 쓰기 오류: \(error)")
            handleError?(error)
        }
    }

    func deleteSearchHistory(query: String) {
        guard let historyToDelete = realm.objects(SearchHistory.self).filter("query == %@", query).first else {
            return
        }

        do {
            try realm.write {
                realm.delete(historyToDelete)
            }
            print("삭제된 검색 이력: \(query)")

            cachedRecentSearches.removeAll(where: { $0 == query })

            updateRecentSearches?()
        } catch {
            print("Realm 쓰기 오류: \(error)")
            handleError?(error)
        }
    }

    func selectRecentSearch(query: String) {
        didSelectRecentSearch?(query)
    }
}
