//
//  FieldView.swift
//  EcoSim
//
//  Created by Stas Kirichok on 25.04.2023.
//

import UIKit
import Combine

struct FieldViewUpdate {
    let grassLevel: Int
    let sheepCount: Int
    let wolfCount: Int
}

class FieldView: UIView, NibLoadable {
    @IBOutlet private weak var sheepCountView: UILabel!
    @IBOutlet private weak var wolfCountView: UILabel!
    
    private var cancellables = Set<AnyCancellable>()
    
    func set(values: AnyPublisher<FieldViewUpdate, Never>) {
        values
            .sink { [weak self] values in
                self?.updateGrassLevel(values.grassLevel)
                self?.sheepCountView.text = values.sheepCount == 0 ? "" : "\(values.sheepCount)"
                self?.wolfCountView.text = values.wolfCount == 0 ? "" : "\(values.wolfCount)"
        }
        .store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func updateGrassLevel(_ grassLevel: Int) {
        let color: UIColor
        switch grassLevel {
        case 1:
            color = .green.withAlphaComponent(0.2)
        case 2:
            color = .green.withAlphaComponent(0.4)
        case 3:
            color = .green
        default:
            color = .gray
        }
        backgroundColor = color
    }
}
