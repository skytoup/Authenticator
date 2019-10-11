//
//  TOTPManager.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/5.
//  Copyright © 2019 test. All rights reserved.
//

import Result
import ReactiveSwift

class TOTPManager {
    struct CalType: OptionSet {
        var rawValue: UInt8
        
        static var current = CalType(rawValue: 1 << 0)
        static var next = CalType(rawValue: 1 << 1)
        
    }
    
    static let share = TOTPManager()
    
    var secretKeys: [String] {
        get {
            return secretKeysProperty.value
        }
        set {
            secretKeysProperty.swap(newValue)
        }
    }
    var updateCodeSignal: Signal<(), NoError> {
        updateCodePip.output
    }
    
    private let timer: Timer
    private let workQueue = DispatchQueue(label: "TOTPWorker")
    lazy private var currentCode = Dictionary<String, Int>()
    lazy private var nextCode = Dictionary<String, Int>()
    lazy private var currentTM = 0
    
    private let tmProperty = MutableProperty(Int(Date().timeIntervalSince1970) / 30)
    private let secretKeysProperty = MutableProperty<[String]>([])
    private let updateCodePip = Signal<(), NoError>.pipe()
    
    fileprivate init() {
        timer = Timer(timeInterval: 0.3, repeats: true) { [weak tmProperty] _ in
            tmProperty?.swap(Int(Date().timeIntervalSince1970) / 30)
        }
        Thread { [weak self] in
            guard let ws = self else { return }
            RunLoop.current.add(ws.timer, forMode: .common)
            RunLoop.current.run()
        }.start()
        
        tmProperty.signal.skipRepeats()
            .observe(on: QueueScheduler(qos: .default, name: workQueue.label, targeting: workQueue))
            .filter { [weak self] in (self?.currentTM ?? $0) != $0 }
            .observeValues { [weak self] _ in
                self?.swapNext()
            }
        secretKeysProperty.signal.skipRepeats().observeValues { [weak self] _ in
            self?.calCode()
        }
    }
    
    deinit {
        timer.invalidate()
    }
    
    func codeFrom(secretKey: String) -> Int? {
        return currentCode[secretKey]
    }
    
    private func calCode(_ calType: CalType = [.current, .next]) {
        workQueue.async { [weak self] in
            guard let ws = self else { return }
            let currentTM = ws.tmProperty.value
            let nextTM = currentTM + 1

            if calType.contains(.next) {
                ws.secretKeys.forEach {
                    if ws.nextCode[$0] == nil, let code = TOTP.genCode(secretKey: $0, tm: nextTM) {
                        ws.nextCode[$0] = code
                    }
                }
            }
            if calType.contains(.current) {
                ws.secretKeys.forEach {
                    if ws.currentCode[$0] == nil, let code = TOTP.genCode(secretKey: $0, tm: currentTM) {
                        ws.currentCode[$0] = code
                    }
                }
                ws.currentTM = currentTM
                ws.updateCodePip.input.send(value: ())
            }
        }
    }
    
    private func swapNext() {
        swap(&currentCode, &nextCode)
        nextCode.removeAll()
        updateCodePip.input.send(value: ())
        calCode([.next])
    }
}
