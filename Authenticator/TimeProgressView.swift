//
//  TimeProgressView.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/22.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import Combine

struct TimeProgressView: View {
    // FIXME: - Xcode 11.4 beta 2 编译Timer.publisher和NavigationView嵌套多层使用有问题
    @ObservedObject fileprivate var myTimer = MyTimer.shared
    
    var body: some View {
        GeometryReader { metry in
            Color(.gray)
            Color(self.myTimer.ts <= 5 ? .red : .blue)
                .frame(width: metry.size.width / 30 * CGFloat(self.myTimer.ts))
        }
        .frame(height: 2)
    }
}

struct TimeProgressView_Previews: PreviewProvider {
    static var previews: some View {
        TimeProgressView()
            .previewLayout(.fixed(width: 320, height: 2))
    }
}
