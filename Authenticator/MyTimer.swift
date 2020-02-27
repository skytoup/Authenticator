//
//  MyTimer.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/22.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

class MyTimer: ObservableObject {
    static let shared = MyTimer()
    
    @Published var ts: CGFloat = 0
    
    lazy var timer = Timer(timeInterval: 1/30, repeats: true) { [weak self] _ in
        self?.ts = 30 - CGFloat(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 30))
    }
    
    fileprivate init() {
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
    }
    
    deinit {
        timer.invalidate()
    }
}
