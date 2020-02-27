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
    // 如果不是每次创建, 显示空视图之后, 计时器会不启动
    fileprivate var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()
    }

    @State fileprivate var ts: TimeInterval = 0
    @ObservedObject fileprivate var dataManager = DataManager.shared
    @ObservedObject fileprivate var totpManager = TOTPManager.shared
    
    @ViewBuilder
    var body: some View {
        if dataManager.datas.isEmpty {
            Text("暂无数据, 请在打开手机的验证器, 自动同步到iWatch或请在手机的验证器添加数据").padding()
        } else {
            VStack {
                TimeProgressView()
                List(dataManager.datas, id: \.secretKey) { data in
                    CodeCell(data: data, code: self.totpManager.currentCode[data.secretKey]?.displayCodeString ?? "--- ---")
                }
            }
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CodeView()
        }
    }
}
