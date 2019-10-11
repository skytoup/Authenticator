//
//  SafeDispatch.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/6.
//  Copyright © 2019 test. All rights reserved.
//

import Foundation

class SafeDispatch {
    static func syncMain(block: () -> Void) {
        if !Thread.isMainThread {
            DispatchQueue.main.sync(execute: block)
        } else {
            block()
        }
    }
}
