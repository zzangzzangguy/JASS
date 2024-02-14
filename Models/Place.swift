//
//  Place.swift
//  JASS
//
//  Created by 김기현 on 12/7/23.
//

import Foundation

struct Place: Codable {
    let name: String
    let formatted_address: String?
    let geometry: Geometry
    let type: String?
    var isGym: Bool {
           let gymKeywords = ["헬스", "피트니스", "휘트니스", "운동센터"]
           return gymKeywords.contains(where: name.localizedCaseInsensitiveContains)
       }
    var isPilates: Bool {
        return name.localizedStandardContains("필라테스")
    }
   }
struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct SearchResults: Codable {
    let results: [Place]
}
