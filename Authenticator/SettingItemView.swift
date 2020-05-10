//
//  SettingItemView.swift
//  Authenticator
//
//  Created by skytoup on 2020/5/10.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct SettingItemView<RightContent: View>: View {
    // MARK: - view
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                if img != nil {
                    img!.resizable().aspectRatio(contentMode: .fit).frame(width: 25, height: 20, alignment: .center)
                }
                
                title
                
                Spacer()
                
                if subtitle != nil {
                    subtitle
                }
                
                if showRightView && rightView != nil {
                    rightView
                }
            }.padding([.top, .bottom])
            
            if showDivider {
                Divider()
            }
        }
        .contentShape(Rectangle())
    }
    
    // MARK: - property
    var img: Image?
    var title: Text
    var subtitle: Text?
    var rightView: RightContent?
    var showRightView: Bool
    var showDivider: Bool
    
    init(img: Image?, title: Text, subtitle: Text? = nil, @ViewBuilder rightView: () -> RightContent?, showRightView: Bool = true, showDivider: Bool = true) {
        self.img = img
        self.title = title
        self.subtitle = subtitle
        self.rightView = rightView()
        self.showRightView = showRightView
        self.showDivider = showDivider
    }
    
}

extension SettingItemView where RightContent == Image {
    init(img: Image?, title: Text, subtitle: Text? = nil, showRightArrow: Bool = true, showDivider: Bool = true) {
        self.init(img: img, title: title, subtitle: subtitle, rightView: { Image(systemName: "chevron.right") }, showRightView: showRightArrow, showDivider: showDivider)
    }
}

struct SettingItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingItemView(img: Image(systemName: "heart"), title: Text("开源项目致谢"))
            SettingItemView(img: Image("black_cat").resizable(), title: Text("作者"), subtitle: Text("喵~").foregroundColor(.gray))
            SettingItemView(img: Image(systemName: "eye"), title: Text("进入后台时模糊显示"), rightView: {
                Text("开").foregroundColor(.gray)
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
                    .frame(width: 50)
            })
        }
        .previewLayout(.fixed(width: 320, height: 53))
            
    }
}
