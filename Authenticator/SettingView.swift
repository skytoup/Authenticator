//
//  SettingView.swift
//  Authenticator
//
//  Created by skytoup on 2020/5/10.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct SettingView: View {
    // MARK: - view
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("安全").font(.subheadline).foregroundColor(.gray)
                    
                    SettingItemView(img: Image(systemName: "lock"), title: Text("启动时验证\(LocalAuth.shared.authTypeStr)"), rightView: {
                        if LocalAuth.shared.isEnable {
                            Text(isOnLa ? "开" : "关").foregroundColor(.gray)
                            Toggle("", isOn: $isOnLa)
                                .labelsHidden()
                                .frame(width: 50)
                                .onTapGesture {
                                    self.toggleAuth()
                            }
                        } else {
                            Text("不可用").foregroundColor(.gray)
                        }
                    }).disabled(!LocalAuth.shared.isEnable)
                    
                    SettingItemView(img: Image(systemName: "eye"), title: Text("进入后台时模糊显示"), rightView: {
                        Text(isOnBgBlur ? "开" : "关").foregroundColor(.gray)
                        Toggle("", isOn: $isOnBgBlur)
                            .labelsHidden()
                            .frame(width: 50)
                            .onTapGesture {
                                self.isOnBgBlur.toggle()
                                AppManager.shared.appItem.isEnableBgBlur = self.isOnBgBlur
                        }
                    } ,showDivider: false)
                    
                }.padding()
            }
            .listStyle(PlainListStyle())
            .modifier(ListSeparatorNoneViewModifier())
            .navigationBarTitle("设置", displayMode: .inline)
            .navigationBarItems(leading: leadingBarItems)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    fileprivate var leadingBarItems: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) { Text("关闭") }
            .padding([.vertical, .trailing], 20)
    }
    
    // MARK: - property
    @Environment(\.presentationMode) fileprivate var presentationMode
    
    @State fileprivate var isOnLa = AppManager.shared.appItem.isEnableOpenAuth
    @State fileprivate var isOnBgBlur =  AppManager.shared.appItem.isEnableBgBlur
    @State fileprivate var isShowAboutView = false
    
    func toggleAuth() {
        if !isOnLa {
            LocalAuth.shared.auth(localizedReason: "开启打开时进行\(LocalAuth.shared.authTypeStr)验证") { success, error in
                if let error = error {
                    HUD.showTextOnWin("开启失败 \(error.localizedDescription)")
                    self.isOnLa = false
                } else {
                    self.isOnLa = true
                    AppManager.shared.appItem.isEnableOpenAuth = true
                }
            }
        } else {
            AppManager.shared.appItem.isEnableOpenAuth = false
        }
    }
    
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}

