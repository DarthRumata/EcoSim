//
//  Field.swift
//  EcoSim
//
//  Created by Stas Kirichok on 10.03.2021.
//

import Combine
import Foundation

struct FieldPosition: CustomDebugStringConvertible {
    let x: Int
    let y: Int
    
    var debugDescription: String {
        return "x: \(x) y: \(y)"
    }
    
    func newPosition(in direction: MoveDirection) -> FieldPosition {
        return FieldPosition(x: direction.x + x, y: direction.y + y)
    }
}

extension FieldPosition: Hashable {}

struct MoveDirection {
    let x: Int
    let y: Int
    
    static let allDirections: [MoveDirection] = [
        MoveDirection(x: -1, y: 0),
        MoveDirection(x: -1, y: 1),
        MoveDirection(x: -1, y: -1),
        MoveDirection(x: 0, y: 1),
        MoveDirection(x: 0, y: -1),
        MoveDirection(x: 1, y: -1),
        MoveDirection(x: 1, y: 0),
        MoveDirection(x: 1, y: 1)
    ]
}

struct FieldValue {
    private let field: Field
    
    var hasGrass: Bool {
        return field.grassLevel > 0
    }
    
    var grassLevel: Int {
        return field.grassLevel
    }
    var grassLevelPublisher: AnyPublisher<Int, Never> {
        return field.$grassLevel.eraseToAnyPublisher()
    }
    
    init(field: Field) {
        self.field = field
    }
}

class Field: TickHandler {
    let id = ProcessInfo.processInfo
    @Published private(set) var grassLevel = 0
    let position: FieldPosition
    private let logObserver: AnySubscriber<String, Never>
    
    init(position: FieldPosition, logObserver: AnySubscriber<String, Never>) {
        self.position = position
        self.logObserver = logObserver
    }
    
    func handleTick() {
        if grassLevel < 3 {
            let newGrassProbability = Float.random(in: 0...1)
            if newGrassProbability > 0.7 {
                grassLevel += 1
               // _ = logObserver.receive("Field \(position): grass grows - level \(grassCount)")
            }
        }
    }
    
    func eatGrass() {
        grassLevel -= 1
    }
}
