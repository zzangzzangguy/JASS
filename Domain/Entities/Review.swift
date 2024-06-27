//
//  Review.swift
//  JASS
//
//  Created by 김기현 on 6/27/24.
//

import Foundation

// Data/Model/Review.swift
struct Review: Codable {
    let authorName: String
    let authorUrl: String?
    let language: String?
    let profilePhotoUrl: String?
    let rating: Int?
    let relativeTimeDescription: String?
    let text: String?
    let time: Int?

    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case authorUrl = "author_url"
        case language
        case profilePhotoUrl = "profile_photo_url"
        case relativeTimeDescription = "relative_time_description"
        case text, rating, time
    }
}
