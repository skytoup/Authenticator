//
//  CodeEditShowState.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/29.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

enum CodeEditShowState: ShowState {
    case dismiss
    case add(params: TOTP.Params? = nil)
    case edit(code: CodeModel)
    
    func isShow() -> Bool {
        if case .dismiss = self {
            return false
        } else {
            return true
        }
    }
    
    mutating func dismiss() {
        self = .dismiss
    }
    
    var view: some View {
        switch self {
        case .dismiss:
            fatalError("can not get view if state is .dismiss")
        case .add(let params):
            return CodeEditView(params: params)
        case .edit(let code):
            return CodeEditView(code: code)
        }
    }
}
