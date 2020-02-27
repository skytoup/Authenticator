//
//  ContentView.swift
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
        Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    }

    @State fileprivate var ts = 0
    @EnvironmentObject fileprivate var totps: TOTPDatas
    
    @ViewBuilder
    var body: some View {
        if totps.items.isEmpty {
            Text("暂无数据, 请在打开手机的验证器, 自动同步到iWatch或请在手机的验证器添加数据").padding()
        } else {
            VStack {
                GeometryReader { metrics in
                    Color(.gray)
                    Color(self.ts <= 5 ? .red : .blue)
                        .frame(width: metrics.size.width / 30 * CGFloat(self.ts))
                }.frame(height: 1)
                List {
                    ForEach(totps.items, id: \.params.secretKey) { item in
                        ACodeRow(item: item)
                    }
                }
            }.onReceive(timer) { _ in
                self.ts = 30 - Int(Date().timeIntervalSince1970) % 30
            }
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var ds: TOTPDatas {
        let ds = TOTPDatas()
        ds.items = [(("name", "234", "remark"), DataManager.defaultTOTPCode)]
        return ds
    }
    
    static var previews: some View {
        Group {
            CodeView()
                .environmentObject(ds)
                .previewDisplayName("有数据")
            CodeView()
                .environmentObject(TOTPDatas())
                .previewDisplayName("无数据")
        }
    }
}
