//
//  TOTPManager.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/5.
//  Copyright © 2019 test. All rights reserved.
//

import SwiftUI
import CoreData
import WatchConnectivity

class TOTPManager: ObservableObject {
    struct CalType: OptionSet {
        var rawValue: UInt8
        
        static var current = CalType(rawValue: 1 << 0)
        static var next = CalType(rawValue: 1 << 1)
    }
    
    static let shared = TOTPManager()
    
    var secretKeys: [String] = [] {
        didSet {
            workQueue.async { [weak self] in
                guard let ws = self else {
                    return
                }
                let new = Set(ws.secretKeys).subtracting(oldValue)
                if new.count != 0 {
                    ws.calCode(tm: ws.currentTM, type: [.next, .current], secretKeys: Array(new))
                }
            }
        }
    }
    
    fileprivate var timer: Timer?
    fileprivate let workQueue = DispatchQueue(label: "TOTPWorker")
    fileprivate(set) var currentCode = [String: Int]()
    fileprivate var nextCode = [String: Int]()
    fileprivate var currentTM = 0
    
    fileprivate init() {
        // 定时检查时间
        timer = Timer(timeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let ws = self else {
                return
            }
            
            let tm = Int(Date().timeIntervalSince1970) / 30
            guard ws.currentTM != tm else {
                return
            }
            
            if ws.currentTM == tm - 1 {
                ws.swapToNext(tm)
            } else {
                ws.calCode(tm: tm, type: [.current, .next], secretKeys: ws.secretKeys)
            }
        }
        Thread { [weak self] in
            guard let timer = self?.timer else {
                return
            }
            RunLoop.current.add(timer, forMode: .common)
            RunLoop.current.run()
        }.start()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    fileprivate func calCode(tm: Int, type: CalType, secretKeys: [String]) {
        workQueue.async { [weak self] in
            guard let ws = self else {
                return
            }
            
            ws.currentTM = tm
            if type.contains(.current) {
                ws.cal(tm: tm, secretKeys: secretKeys, codes: &ws.currentCode, isCur: true)
            }
            if type.contains(.next) {
                ws.cal(tm: tm + 1, secretKeys: secretKeys, codes: &ws.nextCode, isCur: false)
            }
        }
    }
    
    fileprivate func cal(tm: Int, secretKeys: [String], codes: inout [String: Int], isCur: Bool) {
        let ds: [(String, Int)] = secretKeys.compactMap {
            if let code = TOTP.genCode(secretKey: $0, tm: tm) {
                return ($0, code)
            }
            return nil
        }
        DispatchQueue.main.sync {
            ds.forEach {
                codes[$0.0] = $0.1
            }
            if isCur {
                objectWillChange.send()
            }
        }
    }
    
    fileprivate func swapToNext(_ tm: Int) {
        DispatchQueue.main.sync {
            swap(&currentCode, &nextCode)
            objectWillChange.send()
        }
        nextCode.removeAll()
        calCode(tm: tm, type: [.next], secretKeys: secretKeys)
    }
}
