//
//  LocalAuth.swift
//  Authenticator
//
//  Created by skytoup on 2020/5/10.
//  Copyright © 2020 test. All rights reserved.
//

import LocalAuthentication

class LocalAuth {
    static let shared = LocalAuth()
    
    let laContext = LAContext()
    var isEnable: Bool { laContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) }
    fileprivate(set) lazy var authTypeStr: String = {
        switch laContext.biometryType {
        case .faceID:
            return "脸容ID"
        case .touchID:
            return "指纹ID"
        case .none:
            return "锁屏密码"
        @unknown default:
            return "未知"
        }
    }()
    
    fileprivate init() { }
    
    func auth(localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        laContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localizedReason, reply: reply)
    }
}
