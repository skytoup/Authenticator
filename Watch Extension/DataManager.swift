//
//  DataManager.swift
//  Watch Extension
//
//  Created by skytoup on 2020/2/19.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import WatchConnectivity

class DataManager: ObservableObject {
    fileprivate static let dataKey = "__code_datas__"

    static let shared = DataManager()
    
    @Published var datas: [TOTP.Params] = []
    
    fileprivate init() {
        reloadDatas()
    }
    
    func handle(datas: [String: Any]) {
        guard let _ = datas["datas"] as? [[String: String]],
            let ver = datas["ver"] as? String,
            ver == "v1" else {
            return
        }
        UserDefaults.standard.set(datas, forKey: Self.dataKey)
        reloadDatas()
    }
    
    /// 重新加载数据
    fileprivate func reloadDatas() {
        guard let ds = UserDefaults.standard.dictionary(forKey: Self.dataKey)?["datas"] as? [[String:String]] else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let ws = self else {
                return
            }
            ws.datas = ds.reduce(into: [TOTP.Params](), {
                $0.append((
                        $1["account"] ?? "",
                        $1["secretKey"] ?? "",
                        $1["remark"] ?? ""
                ))
            })
            TOTPManager.shared.secretKeys = ws.datas.map(\.secretKey)
        }
    }
    
}
