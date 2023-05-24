//
//  Sheep.swift
//  EcoSim
//
//  Created by Stas Kirichok on 13.03.2021.
//

import Combine
import Foundation

struct SheepValue: Equatable, AnimalValue {
    private let sheep: Sheep
    
    var id: String {
        return sheep.id
    }
    
    var name: String {
        return sheep.name
    }
    
    var gender: Gender {
        return sheep.gender
    }
    
    var isAdult: Bool {
        return sheep.isAdult
    }
    
    var age: Int {
        return sheep.age
    }
    
    var position: FieldPosition {
        return sheep.position
    }
    
    var isStarving: Bool {
        return sheep.isStarving
    }
    
    var isPregnant: Bool {
        return sheep.isPregnant
    }
    
    init(_ sheep: Sheep) {
        self.sheep = sheep
    }
}

class Sheep: Animal {
    override var isAdult: Bool {
        return age > 15
    }
    override var animalValue: AnimalValue {
        return SheepValue(self)
    }
    
    override func naturalDeathProbability() -> Double {
        return 0.00002 * pow(Double(age), 2) - 0.00112 * Double(age) + 0.00397
    }
    
    override func chooseAction() -> Action {
        let currentField = map.field(at: position)
        if isPregnant && pregnancyAge + 2 == age {
            isWaiting = false
            return .giveBirth
        }
        let isSeekingForPartner = isAdult && gender == .male && satietyLevel > 1
        if isSeekingForPartner {
            let breedingSheeps = map.sheeps(at: position).filter({ canBreed(with: $0) })
            if let partner = breedingSheeps.first {
                return .breed(partner)
            }
        }
        
        let canEat = satietyLevel < Animal.maxSatietyLevel
        if !isSeekingForPartner && canEat && currentField.hasGrass {
            return .eat
        }
        
        return isWaiting ? .wait : .move(isSeekingForPartner ? .breed : .eat)
    }
    
    override func applyAction(_ action: Action) {
        switch action {
        case .move(let intention):
            switch intention {
            case .none:
                moveToRandomPosition()
            case .breed:
                let sheepsNearby = map.sheeps(around: position).filter({ canBreed(with: $0) })
                if let partner = sheepsNearby.randomElement() {
                    position = partner.position
                    _ = eventObserver.receive(Animal.Event.MaleCalledFemale(femaleAnimal: partner))
                } else {
                    //print("\(name) is looking for partner")
                    applyAction(.move(.none))
                }
            case .eat:
                let grassNearby = map.availablePositions(around: position).filter({ map.field(at: $0).hasGrass })
                if let grassPosition = grassNearby.randomElement() {
                    position = grassPosition
                } else {
                    applyAction(.move(.none))
                }
            }
        case .eat:
            satietyLevel = min(3, satietyLevel + 2)
            turnsSinceLastFeeding = 0
            _ = eventObserver.receive(Event.FoodFound(animal: SheepValue(self), position: position))
            
        case .breed(let partner):
            satietyLevel -= 1
            _ = eventObserver.receive(Animal.Event.BreedingPairFound(male: SheepValue(self), female: partner))
        case .giveBirth:
            isPregnant = false
            _ = eventObserver.receive(Animal.Event.BirthGiven(mother: SheepValue(self)))
        case .wait:
            //print("\(name) is waiting for partner")
            break
        }
    }
}


