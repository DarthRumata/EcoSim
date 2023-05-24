//
//  MapView.swift
//  EcoSim
//
//  Created by Stas Kirichok on 25.04.2023.
//

import UIKit
import Combine

class MapView: UIView {
    private var map: MapValue!
    private var fieldViews = [FieldPosition: FieldView]()
    private var cancellables = Set<AnyCancellable>()
    
    func configure(map: MapValue, events: AnyPublisher<AnimalEvent, Never>) {
        self.map = map
        
        processEvents(events)
        
        var constraints = [NSLayoutConstraint]()
        for y in 0..<map.size {
            for x in 0..<map.size {
                let position = FieldPosition(x: x, y: y)
                let field = map.field(at: position)
                let fieldView = makeFieldView(field: field)
                let fieldSheeps = map.sheepsPublisher(at: position)
                let updates = fieldSheeps
                    .map { $0.count }
                    .combineLatest(field.grassLevelPublisher)
                    .map { (sheepCount, grassLevel) in
                        FieldViewUpdate(grassLevel: grassLevel, sheepCount: sheepCount, wolfCount: 0)
                    }
                    .eraseToAnyPublisher()
                fieldView.set(values: updates)
                fieldViews[position] = fieldView
                addSubview(fieldView)
                
                // Make constraints
                let fieldConstraints = makeConstraints(for: fieldView, at: position)
                constraints.append(contentsOf: fieldConstraints)
            }
        }
        NSLayoutConstraint.activate(constraints)
        layoutIfNeeded()
    }
    
    private func processEvents(_ events: AnyPublisher<AnimalEvent, Never>) {
        events
            .sink { [weak self] event in
                switch event {
                case is Animal.Event.Death:
                    if let targetField = self?.fieldViews[event.position] {
                        let messageView = MapMessageView.loadFromNib()
                        let orientation: MapMessageView.Orientation = event.position.x > 5 ? .left : .right
                        messageView.configure(orientation: orientation, event: event)
                        self?.addSubview(messageView)
                        var constraints = [targetField.centerYAnchor.constraint(equalTo: messageView.bottomAnchor)]
                        let constraint: NSLayoutConstraint
                        if orientation == .right {
                            constraint = targetField.trailingAnchor.constraint(equalTo: messageView.leadingAnchor)
                        } else {
                            constraint = targetField.leadingAnchor.constraint(equalTo: messageView.trailingAnchor)
                        }
                        constraints.append(constraint)
                        NSLayoutConstraint.activate(constraints)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func makeFieldView(field: FieldValue) -> FieldView {
        let view = FieldView.loadFromNib()
        return view
    }
    
    private func makeConstraints(for field: FieldView, at position: FieldPosition) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        
        let ratio = field.widthAnchor.constraint(equalTo: field.heightAnchor, multiplier: 1)
        constraints.append(ratio)
        if position.y == 0 {
            let top = field.topAnchor.constraint(equalTo: topAnchor)
            constraints.append(top)
        } else if position.y == map.size - 1 {
            let bottom = field.bottomAnchor.constraint(equalTo: bottomAnchor)
            constraints.append(bottom)
            let top = makeUpperConstraint(for: field, at: position)
            constraints.append(top)
        } else {
            let top = makeUpperConstraint(for: field, at: position)
            constraints.append(top)
        }
        
        if position.x == 0 {
            let leading = field.leadingAnchor.constraint(equalTo: leadingAnchor)
            constraints.append(leading)
        } else if position.x == map.size - 1 {
            let trailing = field.trailingAnchor.constraint(equalTo: trailingAnchor)
            constraints.append(trailing)
            let leading = makeLeftConstraint(for: field, at: position)
            constraints.append(leading)
        } else {
            let leading = makeLeftConstraint(for: field, at: position)
            constraints.append(leading)
        }
        
        if position.x != 0 && position.y != 0 {
            let firstPosition = FieldPosition(x: 0, y: 0)
            if let firstField = fieldViews[firstPosition] {
                let width = field.widthAnchor.constraint(equalTo: firstField.widthAnchor)
                constraints.append(width)
                let height = field.heightAnchor.constraint(equalTo: firstField.heightAnchor)
                constraints.append(height)
            }
        }
        
        return constraints
    }
    
    private func makeUpperConstraint(for field: FieldView, at position: FieldPosition) -> NSLayoutConstraint {
        let upperFieldPosition = FieldPosition(x: position.x, y: position.y - 1)
        if let upperField = fieldViews[upperFieldPosition] {
            return field.topAnchor.constraint(equalTo: upperField.bottomAnchor)
        } else {
            fatalError("Upper field should always exists. Check map size")
        }
    }
    
    private func makeLeftConstraint(for field: FieldView, at position: FieldPosition) -> NSLayoutConstraint {
        let leftFieldPosition = FieldPosition(x: position.x - 1, y: position.y)
        if let leftField = fieldViews[leftFieldPosition] {
            return field.leadingAnchor.constraint(equalTo: leftField.trailingAnchor)
        } else {
            fatalError("Left field should always exists. Check map size")
        }
    }
}
