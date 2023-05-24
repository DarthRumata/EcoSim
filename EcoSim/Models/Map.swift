//
//  Map.swift
//  EcoSim
//
//  Created by Stas Kirichok on 13.03.2021.
//

import Foundation
import Combine

struct MapValue {
    var size: Int {
        return map.size
    }
    
    private let map: Map
    
    init(map: Map) {
        self.map = map
    }
    
    func field(at position: FieldPosition) -> FieldValue {
        return FieldValue(field: map.field(at: position))
    }
    
    func sheeps(at position: FieldPosition) -> [SheepValue] {
        return map.sheeps(at: position).map { SheepValue($0) }
    }
    
    func sheepsPublisher(at position: FieldPosition) -> AnyPublisher<[SheepValue], Never> {
        return map.sheepsPublisher(at: position)
            .map { $0.map { SheepValue($0) } }
            .eraseToAnyPublisher()
    }
    
    func sheeps(around position: FieldPosition) -> [SheepValue] {
        let availablePositions = self.availablePositions(around: position)
        return availablePositions.flatMap { sheeps(at: $0) }
    }
    
    func canMove(to position: FieldPosition) -> Bool {
        return position.x >= 0 && position.x <= map.size && position.y >= 0 && position.y <= map.size
    }
    
    func availableDirections(for position: FieldPosition) -> [MoveDirection] {
        let directions = MoveDirection.allDirections
        typealias Condition = (MoveDirection) -> Bool
        var conditions = [Condition]()
        if position.x == 0 {
            conditions.append ({ $0.x >= 0 })
        }
        if position.x == map.size - 1 {
            conditions.append ({ $0.x <= 0 })
        }
        if position.y == 0 {
            conditions.append ({ $0.y >= 0 })
        }
        if position.y == map.size - 1 {
            conditions.append ({ $0.y <= 0 })
        }
        return directions.filter { (direction) -> Bool in
            return conditions.allSatisfy { (condition) -> Bool in
                return condition(direction)
            }
        }
    }
    
    func availablePositions(around position: FieldPosition) -> [FieldPosition] {
        let directions = availableDirections(for: position)
        return directions.map { position.newPosition(in: $0) }
    }
}

class Map {
    var sheepsAliveCount: AnyPublisher<Int, Never> {
        return $sheeps.map { $0.count }.eraseToAnyPublisher()
    }
    var deadSheepsCount: AnyPublisher<Int, Never> {
        return deadSheepsCountSubject.eraseToAnyPublisher()
    }
    
    fileprivate var fields = [Field]()
    
    private let maleSheepNameGenerator = NameGenerator(type: .sheep, gender: .male)
    private let femaleSheepNameGenerator = NameGenerator(type: .sheep, gender: .female)
    private let deadSheepsCountSubject = CurrentValueSubject<Int, Never>(0)
    @Published private(set) var sheeps = [Sheep]()
    fileprivate let size: Int
    
    private let logObserver: LogObserver
    private let eventObserver: AnySubscriber<AnimalEvent, Never>
    
    init(logObserver: LogObserver, eventObserver: AnySubscriber<AnimalEvent, Never>, size: Int) {
        self.logObserver = logObserver
        self.eventObserver = eventObserver
        self.size = size
        fields.reserveCapacity(size * size)
        for y in 0..<size {
            for x in 0..<size {
                let position = FieldPosition(x: x, y: y)
                let field = Field(position: position, logObserver: logObserver)
                fields.append(field)
            }
        }
    }
    
    func generateSheeps() {
        sheeps = [
            makeSheep(at: FieldPosition(x: 0, y: 1), gender: .male),
            makeSheep(at: FieldPosition(x: 4, y: 2), gender: .male),
            makeSheep(at: FieldPosition(x: 5, y: 6), gender: .male),
            makeSheep(at: FieldPosition(x: 7, y: 6), gender: .female),
            makeSheep(at: FieldPosition(x: 2, y: 2), gender: .female),
            makeSheep(at: FieldPosition(x: 7, y: 8), gender: .female)
        ]
        deadSheepsCountSubject.value = 0
    }
    
    func addSheep() {
        var currentSheeps = sheeps
        let position = FieldPosition(x: Int.random(in: 0..<size), y: Int.random(in: 0..<size))
        let gender: Gender = Bool.random() ? .male : .female
        let sheep = makeSheep(at: position, gender: gender)
        currentSheeps.append(sheep)
        sheeps = currentSheeps
    }
    
    func eatGrass(at position: FieldPosition) {
        let field = self.field(at: position)
        field.eatGrass()
    }
    
    fileprivate func field(at position: FieldPosition) -> Field {
        return fields[position.y * size + position.x]
    }
    
    fileprivate func sheeps(at position: FieldPosition) -> [Sheep] {
        return sheeps.filter({ $0.position == position })
    }
    
    fileprivate func sheepsPublisher(at position: FieldPosition) -> AnyPublisher<[Sheep], Never> {
        return $sheeps.map { $0.filter { $0.position == position } }.eraseToAnyPublisher()
    }
    
    private func markSheepAsPregnant(_ value: AnimalValue) {
        let sheep = sheeps.first(where: { $0.id == value.id })
        sheep?.isPregnant = true
    }
    
    private func makeSheep(at position: FieldPosition, gender: Gender) -> Sheep {
        return Sheep(
            position: position,
            age: 0,
            name: gender == .male ? maleSheepNameGenerator.generate() : femaleSheepNameGenerator.generate(),
            gender: gender,
            map: MapValue(map: self),
            eventObserver: AnySubscriber<AnimalEvent, Never>(receiveValue: { [weak self] event in
                guard let self = self else {
                    return .unlimited
                }
                _ = self.eventObserver.receive(event)
                switch event {
                case let event as Animal.Event.Death:
                    self.sheeps = self.sheeps.filter({ $0.id != event.animal.id })
                    self.deadSheepsCountSubject.value = self.deadSheepsCountSubject.value + 1
                    _ = self.logObserver.receive("Sheep \(event.animal.name) is dead: \(event.deathType) at age \(event.animal.age)")
                    
                case let event as Animal.Event.FoodFound:
                    self.eatGrass(at: event.position)
                    _ = self.logObserver.receive("Sheep \(event.animal.name) eat grass at \(event.position)")
                    
                case let event as Animal.Event.BreedingPairFound:
                    self.markSheepAsPregnant(event.female)
                    _ = self.logObserver.receive("Sheep \(event.male.name) breed with \(event.female.name) at \(event.male.position)")
                    
                case let event as Animal.Event.BirthGiven:
                    let newborn = self.makeSheep(at: event.mother.position, gender: Bool.random() ? .male : .female)
                    var currentSheeps = self.sheeps
                    currentSheeps.append(newborn)
                    self.sheeps = currentSheeps
                    _ = self.logObserver.receive("Sheep \(event.mother.name) bore new sheep \(newborn.name)")
                    
                case let event as Animal.Event.StarvationStarted:
                    _ = self.logObserver.receive("Sheep \(event.animal.name) is starving")
                    
                case let event as Animal.Event.MaleCalledFemale:
                    let sheep = sheeps.first(where: { $0.id == event.femaleAnimal.id })
                    sheep?.isWaiting = true
                    
                default:
                    break
                }
                return .unlimited
            }))
    }
}

extension Map: TickHandler {
    func handleTick() {
        fields.forEach { (field) in
            field.handleTick()
        }
        sheeps.forEach({ $0.handleTick() })
    }
}
