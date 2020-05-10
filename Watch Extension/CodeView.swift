//
//  CodeView.swift
//  WatchApp WatchKit Extension
//
//  Created by skytoup on 2020/2/19.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

struct CodeView: View {
    
    // MARK: - view
    @ViewBuilder
    var body: some View {
        if dataManager.datas.isEmpty {
            Text("暂无数据, 请在打开手机的验证器, 自动同步到iWatch或请在手机的验证器添加数据").padding()
        } else {
            VStack {
                TimeProgressView()
                List(dataManager.datas, id: \.secretKey) { data in
                    CodeCell(data: data, code: self.totpManager.currentCode[data.secretKey]?.displayCodeString ?? "--- ---", isRefreshSoon: self.isRefreshSoon)
                }
            }.onReceive(MyTimer.shared.$ts.map { $0 <= 5 }) {
                self.isRefreshSoon = $0
            }
        }
    }
    
    // MARK: - property
    @ObservedObject fileprivate var dataManager = DataManager.shared
    @ObservedObject fileprivate var totpManager = TOTPManager.shared
    
    @State fileprivate var isRefreshSoon = false

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CodeView()
        }
    }
}
