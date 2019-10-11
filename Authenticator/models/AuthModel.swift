//
//  AuthModel.swift
//  Authenticator
//
//  Created by skytoup on 2019/9/29.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit
import RealmSwift

// 认证模型
class AuthModel: Object {
    @objc dynamic var secretKey = "" // 秘钥
    @objc dynamic var account = "" // 账号
    @objc dynamic var remark = "" // 备注
    @objc dynamic var score = 0 // 排序
    
    override class func indexedProperties() -> [String] {
        return [
            "score",
            "secretKey"
        ]
    }
}
