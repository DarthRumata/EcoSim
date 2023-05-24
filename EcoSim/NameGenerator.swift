//
//  NameGenerator.swift
//  EcoSim
//
//  Created by Stas Kirichok on 14.03.2021.
//

import Foundation

enum NameType {
    case sheep
    case wolf
}

enum Gender {
    case male
    case female
}

final class NameGenerator {
    private let namePool: [String]
    private var hits = [Int: Int]()
    
    init(type: NameType, gender: Gender) {
        switch (type, gender) {
        case (.sheep, .male):
            namePool = ["John", "Henry", "Barry", "Tom", "Sam", "Jack"]
        case (.sheep, .female):
            namePool = ["Mary", "Lisa", "Joan", "Katy", "Penny", "Emma"]
        case (.wolf, .male):
            namePool = ["Hans", "Adolf", "Martin", "Herman", "Egon", "Aldis"]
        case (.wolf, .female):
            namePool = ["Anna", "Helga", "Heike", "Edith", "Laura", "Ingrid"]
        }
    }
    
    func generate() -> String {
        let randomIndex = Int.random(in: 0..<namePool.count)
        let name = namePool[randomIndex]
        if var hitCount = hits[randomIndex] {
            hitCount += 1
            hits[randomIndex] = hitCount
            return "\(name)-\(hitCount)"
        } else {
            hits[randomIndex] = 1
        }
        
        return name
    }
}
