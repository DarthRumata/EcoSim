//
//  MapMessageView.swift
//  EcoSim
//
//  Created by Stas Kirichok on 27.04.2023.
//

import UIKit

private struct MessageConfiguration {
    let message: String
    let color: UIColor
}

class MapMessageView: UIView, NibLoadable {
    enum Orientation {
        case left
        case right
    }
    
    @IBOutlet private weak var leftArrow: UIImageView!
    @IBOutlet private weak var rightArrow: UIImageView!
    @IBOutlet private weak var messageView: UILabel!
    @IBOutlet private weak var backgroundView: UIView!
    private var orientation: Orientation!
    
    private let borderLayer = CAShapeLayer()
    
    func configure(orientation: Orientation, event: AnimalEvent) {
        self.orientation = orientation
        
        leftArrow.isHidden = orientation == .left
        rightArrow.isHidden = orientation == .right
        messageView.textColor = event.messageConfiguration.color
        messageView.text = event.messageConfiguration.message
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let timer = Timer(timeInterval: 5, repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.removeFromSuperview()
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        borderLayer.borderWidth = 1
        layer.insertSublayer(borderLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let borderPath = UIBezierPath()
        let startPoint = CGPoint(
            x: backgroundView.frame.origin.x - borderLayer.borderWidth,
            y: backgroundView.frame.origin.y - borderLayer.borderWidth
        )
        borderPath.move(to: startPoint)
        let backgroundRightX = backgroundView.frame.origin.x + backgroundView.frame.width + borderLayer.borderWidth
        borderPath.addLine(to: CGPoint(x: backgroundRightX, y: startPoint.y))
        let bottomY = backgroundView.frame.origin.y + backgroundView.frame.height + borderLayer.borderWidth
        if orientation == .right {
            borderPath.addLine(to: CGPoint(
                x: backgroundRightX,
                y: bottomY
            ))
            borderPath.addLine(to: CGPoint(x: startPoint.x, y: bottomY))
            borderPath.addLine(to: CGPoint(x: leftArrow.frame.origin.x - borderLayer.borderWidth, y: leftArrow.frame.origin.y + leftArrow.frame.height / 2))
            borderPath.addLine(to: CGPoint(x: startPoint.x, y: leftArrow.frame.origin.y))
        } else {
            borderPath.addLine(to: CGPoint(
                x: backgroundRightX,
                y: rightArrow.frame.origin.y - borderLayer.borderWidth
            ))
            borderPath.addLine(to: CGPoint(x: rightArrow.frame.origin.x + rightArrow.frame.width + borderLayer.borderWidth, y: rightArrow.frame.origin.y + rightArrow.frame.height / 2))
            
            borderPath.addLine(to: CGPoint(x: backgroundRightX, y: bottomY))
            borderPath.addLine(to: CGPoint(x: startPoint.x, y: bottomY))
        }
        borderPath.addLine(to: startPoint)
        borderPath.close()
        
        borderLayer.path = borderPath.cgPath
    }
}

private extension AnimalEvent {
    var messageConfiguration: MessageConfiguration {
        switch self {
        case let event as Animal.Event.Death:
            return MessageConfiguration(message: "💀(\(event.deathType.symbol))\nAge: \(event.animal.age)", color: .red)
        default:
            fatalError("We shouldn't call message view if we can't process event")
        }
    }
}

private extension DeathType {
    var symbol: String {
        switch self {
        case .natural:
            return "⚰️"
        case .starvation:
            return "🍽️"
        case .killed:
            return "🏹"
        }
    }
}
