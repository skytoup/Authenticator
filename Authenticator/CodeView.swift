//
//  CodeView.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/21.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import CoreData
import Combine
import MBProgressHUD

struct CodeView: View {
    @Environment(\.managedObjectContext) fileprivate var moc
    @FetchRequest(fetchRequest: Self.fr) var codes: FetchedResults<CodeModel>
    
    static var fr: NSFetchRequest<CodeModel> {
        let req = NSFetchRequest<CodeModel>(entityName: CodeModel.name)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \CodeModel.score, ascending: true)]
        req.fetchLimit = 1
        return req
    }
    
    @State fileprivate var isShowScanView = false
    @State fileprivate var isShowImgPickerView = false
    @State fileprivate var isShowDelAlert = false
    @State fileprivate var isShowManageSheet = false
    @State fileprivate var isShowAddSheet = false
    @State fileprivate var isEditting = false

    @State fileprivate var kw = ""
    
    @State fileprivate var codeEditShowState = CodeEditShowState.dismiss
    
    @ViewBuilder
    fileprivate var leadingBarItems: some View {
        if isEditting {
            EmptyView()
        } else {
            Button(action: {
                self.isShowManageSheet = true
            }) { Image(systemName: "square.grid.2x2") }
            .padding([.trailing, .vertical], 15)
            .actionSheet(isPresented: $isShowAddSheet) { () -> ActionSheet in
                ActionSheet(title: Text("添加验证码"), message: nil, buttons: [
                    .default(Text("扫描二维码"), action: { self.isShowScanView = true }),
                    .default(Text("相册选择"), action: { self.isShowImgPickerView = true }),
                    .default(Text("手动输入"), action: { self.codeEditShowState = .add() }),
                    .cancel(Text("取消"))
                ])
            }
            .sheet(isPresented: $isShowImgPickerView) {
                ImagePicker { info in
                    guard let img = info[.originalImage] as? UIImage, let cgImg = img.cgImage else {
                        HUD.showTextOnWin("获取图片失败")
                        return
                    }
                    self.handleQR(img: CIImage(cgImage: cgImg))
                }
            }
        }
    }
    fileprivate var trailingBatItems: some View {
        Button(action: {
            if self.isEditting {
                self.isEditting = false
            } else {
                self.isShowAddSheet = true
            }
        }) {
            if self.isEditting {
                Text("完成")
            } else {
                Image(systemName: "plus")
            }
        }
        .padding([.leading, .vertical], 15)
        .actionSheet(isPresented: $isShowManageSheet) { () -> ActionSheet in
            ActionSheet(title: Text("管理"), message: nil, buttons: [
                .default(Text("编辑"), action: { self.isEditting = true }),
                .cancel(Text("取消"))
            ])
        }
        
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                NavigationLink(destination:
                    LBXScan(isShow: $isShowScanView) { qrStr in
                        self.handleQR(str: qrStr)
                    }
                    .edgesIgnoringSafeArea(.all)
                    .navigationBarTitle("扫描二维码"), isActive: $isShowScanView) {
                    EmptyView()
                }
                
                if !codes.isEmpty {
                    TimeProgressView()
                    TextField("搜索关键字", text: $kw)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                CodeList(kw: kw, isEditting: $isEditting)
            }
            .edgesIgnoringSafeArea(isEditting ? .bottom : .init())
            .navigationBarTitle("验证码", displayMode: .inline)
            .navigationBarItems(leading: leadingBarItems, trailing: trailingBatItems)
        }
        .sheet(isPresented: $codeEditShowState.isShow) {
            self.codeEditShowState.view
                .environment(\.managedObjectContext, self.moc)
        }
    }
    
    fileprivate func handleQR(img: CIImage) {
        let hud = HUD.showWaitTextOnWin("识别中...")
        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                DispatchQueue.main.async {
                    hud?.hide(animated: true)
                }
            }
            
            guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow]), let features = detector.features(in: img) as? [CIQRCodeFeature] else {
                HUD.showTextOnWin("系统不支持识别二维码")
                return
            }
            guard features.count > 0, let qrStr = features.first?.messageString else {
                HUD.showTextOnWin("识别二维码失败")
                return
            }
            
            self.handleQR(str: qrStr)
        }
    }
    
    fileprivate func handleQR(str: String) {
        do {
            let ds = try TOTP.parseURL(str)
            DispatchQueue.main.async {
                self.codeEditShowState = .add(params: ds)
            }
        } catch let error as TOTP.ParseError {
            switch error {
            case .URL:
                HUD.showTextOnWin("解析链接错误")
            case .secretKey:
                HUD.showTextOnWin("解析秘钥错误")
            case .type:
                HUD.showTextOnWin("只支持TOTP(基于时间点的验证)")
            }
        } catch {
            HUD.showTextOnWin("解析错误")
        }
    }
}

struct CodeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return CodeView().environment(\.managedObjectContext, context)
    }
}
