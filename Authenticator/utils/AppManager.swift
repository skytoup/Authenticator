//
//  AppManager.swift
//  Authenticator
//
//  Created by skytoup on 2020/5/10.
//  Copyright © 2020 test. All rights reserved.
//

import SimpleStoreData

class AppManager {
    
    static let shared = AppManager()
    
    @StoreKeychainW(service: "setting", account: "app") var appItem: AppStoreItem
    
    fileprivate init() { }
}

struct AppStoreItem: CodableDataStoreItem {
    
    var isEnableOpenAuth = false // 是否开启启动时进行TouchID/FaceID验证
    var isEnableBgBlur = true // 是否开启进入后台时, 模糊显示
    
    init() {
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isEnableOpenAuth = try container.decodeIfPresent(Bool.self, forKey: .isEnableOpenAuth) ?? false
        isEnableBgBlur = try container.decodeIfPresent(Bool.self, forKey: .isEnableBgBlur) ?? true
    }
    
}

