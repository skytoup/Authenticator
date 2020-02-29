//
//  ShowStateProtocol.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/29.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation

protocol ShowState {
    func isShow () -> Bool
    mutating func dismiss()
}

extension ShowState {
    var isShow: Bool {
        get {
            isShow()
        }
        set {
            guard !newValue else {
                return
            }
            dismiss()
        }
    }
}
