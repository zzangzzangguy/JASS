import Foundation

struct Photo: Codable {
    let height: Int
    let width: Int
    let photoReference: String

    enum CodingKeys: String, CodingKey {
        case height
        case width
        case photoReference = "photo_reference"
    }
}
