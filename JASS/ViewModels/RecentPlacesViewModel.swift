import Foundation

class RecentPlacesViewModel {
    var recentPlaces: [Place] = []

    func addRecentPlace(place: Place) {
        if !recentPlaces.contains(where: { $0.name == place.name }) {
            recentPlaces.append(place)
            if recentPlaces.count > 10 {
                recentPlaces.removeFirst()
            }
        }
    }

    func loadRecentPlaces() -> [Place] {
        return recentPlaces
    }
}
