//
//  Animal.swift
//  EcoSim
//
//  Created by Stas Kirichok on 18.03.2021.
//

import Foundation
import Combine

enum DeathType: CustomDebugStringConvertible {
    case natural
    case starvation
    case killed
    
    var debugDescription: String {
        switch self {
        case .natural:
            return "natural"
        case .starvation:
            return "starvation"
        case .killed:
            return "killed"
        }
    }
}

protocol AnimalValue {
    var id: String { get }
    var position: FieldPosition { get }
    var isAdult: Bool { get }
    var age: Int { get }
    var name: String { get }
    var gender: Gender { get }
    var isStarving: Bool { get }
    var isPregnant: Bool { get }
}

class Animal: Equatable {
    enum Action {
        case move(MoveIntention)
        case eat
        case breed(AnimalValue)
        case giveBirth
        case wait
    }
    enum MoveIntention {
        case eat
        case breed
        case none
    }

    static let maxSatietyLevel = 3
    static func == (lhs: Animal, rhs: Animal) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = ProcessInfo.processInfo.globallyUniqueString
    var position: FieldPosition
    var age: Int
    let name: String
    let gender: Gender
    var isPregnant = false {
        didSet {
            pregnancyAge = age
        }
    }
    var satietyLevel = Animal.maxSatietyLevel
    var turnsSinceLastFeeding = 0
    var pregnancyAge = 0
    var isWaiting = false
    
    var isAdult: Bool {
        return false
    }
    var isStarving: Bool {
        return satietyLevel == 0
    }
    var animalValue: AnimalValue {
        fatalError("Should be overriden")
    }
    
    let map: MapValue
    let eventObserver: AnySubscriber<AnimalEvent, Never>
    
    init(position: FieldPosition, age: Int, name: String, gender: Gender, map: MapValue, eventObserver: AnySubscriber<AnimalEvent, Never>) {
        self.position = position
        self.age = age
        self.name = name
        self.gender = gender
        self.map = map
        self.eventObserver = eventObserver
    }
    
    func canBreed(with other: AnimalValue) -> Bool {
        return other.gender != gender && other.isAdult && !other.isStarving && !other.isPregnant
    }
    
    func naturalDeathProbability() -> Double {
        return 0
    }
    
    private func calculateState() -> Bool {
        let naturalDeathProbability = naturalDeathProbability()
        let starvationDeathProbability = satietyLevel == 0 ? 0.4 : 0
        
        let deathStochasticValue = Double.random(in: 0...1)
        var deathType: DeathType?

        if deathStochasticValue < naturalDeathProbability {
            deathType = .natural
        } else if deathStochasticValue < naturalDeathProbability + starvationDeathProbability {
            deathType = .starvation
        }
        
        if let deathType = deathType {
            _ = eventObserver.receive(Animal.Event.Death(animal: animalValue, deathType: deathType))
            return false
        }
        
        age += 1
        turnsSinceLastFeeding += 1
        if turnsSinceLastFeeding == 2 {
            satietyLevel -= 1
            turnsSinceLastFeeding = 0
        }
        
        if satietyLevel == 0 {
            _ = eventObserver.receive(Animal.Event.StarvationStarted(animal: animalValue))
        }
        
        return true
    }
    
    func chooseAction() -> Action {
        return .move(.none)
    }
    
    func applyAction(_ action: Action) {
        fatalError("should be overriden")
    }
    
    func moveToRandomPosition() {
        if let direction = map.availableDirections(for: position).randomElement() {
            let newPosition = position.newPosition(in: direction)
            position = newPosition
        }
    }
}

extension Animal: TickHandler {
    func handleTick() {
        let canContinue = calculateState()
        if canContinue {
            let action = chooseAction()
            applyAction(action)
        }
    }
}

protocol AnimalEvent {
    var position: FieldPosition { get }
}

extension Animal {
    enum Event {
        struct Death: AnimalEvent {
            let animal: AnimalValue
            let deathType: DeathType
            
            var position: FieldPosition {
                return animal.position
            }
        }
        struct BreedingPairFound: AnimalEvent {
            let male: AnimalValue
            let female: AnimalValue
            
            var position: FieldPosition {
                return male.position
            }
        }
        struct MaleCalledFemale: AnimalEvent {
            let femaleAnimal: AnimalValue
            
            var position: FieldPosition {
                return femaleAnimal.position
            }
        }
        struct BirthGiven: AnimalEvent {
            let mother: AnimalValue
            
            var position: FieldPosition {
                return mother.position
            }
        }
        struct StarvationStarted: AnimalEvent {
            let animal: AnimalValue
            
            var position: FieldPosition {
                return animal.position
            }
        }
        struct FoodFound: AnimalEvent {
            let animal: AnimalValue
            let position: FieldPosition
        }
    }
}
