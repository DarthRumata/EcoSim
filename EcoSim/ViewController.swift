//
//  ViewController.swift
//  EcoSim
//
//  Created by Stas Kirichok on 10.03.2021.
//

import UIKit
import Combine

typealias LogObserver = AnySubscriber<String, Never>

class ViewController: UIViewController {
    
    private var turnCount = 0 {
        didSet {
            for turnIndex in oldValue..<turnCount {
                logs.append("Turn \(turnIndex)")
                turnsLabel.text = "Turn \(turnCount)"
                map.handleTick()
            }
        }
    }
    private lazy var logObserver = LogObserver(receiveValue: { [weak self] value in
        self?.logs.append(value)
        return .unlimited
    })
    private lazy var map = Map(
        logObserver: logObserver,
        eventObserver: AnySubscriber<AnimalEvent, Never>(receiveValue: { [weak self] event in
            self?.eventsRelay.send(event)
            return .unlimited
        }),
        size: 10
    )
    
    @Published private var logs = [String]()
    private var autoModeTimer: Timer?
    private let eventsRelay = PassthroughSubject<AnimalEvent, Never>()
    private var cancellableSet = Set<AnyCancellable>()
    
    @IBOutlet private weak var sheepsAliveLabel: UILabel!
    @IBOutlet private weak var sheepsDeadLabel: UILabel!
    @IBOutlet private weak var wolvesAliveLabel: UILabel!
    @IBOutlet private weak var wolvesDeadLabel: UILabel!
    @IBOutlet private weak var mapView: MapView!
    @IBOutlet private weak var logView: UITextView!
    @IBOutlet private weak var turnsLabel: UILabel!
    @IBOutlet private weak var modeButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        $logs
            .throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] (logItems) in
                guard let self = self else {
                    return
                }
                self.logView.text = logItems.reduce(into: "", { partialResult, item in
                    partialResult += "\n \(item)"
                })
                self.logView.scrollRangeToVisible(NSRange(location: self.logView.text.count, length: 1))
            }
            .store(in: &cancellableSet)
        map.sheepsAliveCount
            .sink { [weak self] count in
                self?.sheepsAliveLabel.text = "\(count)"
            }
            .store(in: &cancellableSet)
        map.deadSheepsCount
            .sink { [weak self] count in
                self?.sheepsDeadLabel.text = "\(count)"
            }
            .store(in: &cancellableSet)
        
        map.generateSheeps()
        
        mapView.configure(map: MapValue(map: map), events: eventsRelay.eraseToAnyPublisher())
    }

    @IBAction private func handleTapOnOneTurn(_ sender: Any) {
        turnCount += 1
    }
    @IBAction private func handleTapOnFiveTurns(_ sender: Any) {
        turnCount += 5
    }
    @IBAction private func handleTapOnTenTurns(_ sender: Any) {
        if let autoModeTimer = autoModeTimer {
            autoModeTimer.invalidate()
            self.autoModeTimer = nil
            modeButton.setTitle("Auto mode", for: .normal)
        } else {
            let autoModeTimer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
                self?.handleTapOnOneTurn(sender)
            }
            RunLoop.current.add(autoModeTimer, forMode: .common)
            self.autoModeTimer = autoModeTimer
            modeButton.setTitle("Manual mode", for: .normal)
        }
    }
    @IBAction func handleNewGameTapped(_ sender: Any) {
        map.generateSheeps()
    }
    @IBAction func handleAddSheepTapped(_ sender: Any) {
        map.addSheep()
    }
    @IBAction func handleAddWolfTapped(_ sender: Any) {
    }
}

