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
    fileprivate enum CodeEditState {
        case dismiss
        case add(params: TOTP.Params? = nil)
        case edit(code: CodeModel)
        
        var isShow: Bool {
            get {
                if case .dismiss = self {
                    return false
                } else {
                    return true
                }
            }
            set {
                guard !newValue else {
                    return
                }
                self = .dismiss
            }
        }
        
        var view: some View {
            switch self {
            case .dismiss:
                fatalError("can not get view if state is .dismiss")
            case .add(let params):
                return CodeEditView(params: params)
            case .edit(let code):
                return CodeEditView(code: code)
            }
        }
    }
    
    fileprivate enum CodeQRState {
        case dismiss
        case show(code: CodeModel)
        
        var isShow: Bool {
            get {
                if case .dismiss = self {
                    return false
                } else {
                    return true
                }
            }
            set {
                guard !newValue else {
                    return
                }
                self = .dismiss
            }
        }
        
        var view: some View {
            switch self {
            case .dismiss:
                fatalError("can not get view if state is .dismiss")
            case .show(let code):
                return CodeQRView(code: code)
            }
        }
    }
    
    @Environment(\.managedObjectContext) fileprivate var moc
    @FetchRequest(
        entity: CodeModel.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeModel.score, ascending: true)]
    ) var codes: FetchedResults<CodeModel>
    
    @State fileprivate var isShowScanView = false
    @State fileprivate var isShowImgPickerView = false
    @State fileprivate var isShowDelAlert = false
    @State fileprivate var isShowManageSheet = false
    @State fileprivate var isShowAddSheet = false
    @State fileprivate var isEditting = false
    @State fileprivate var codeSelection = Set<UUID?>()
    
    @State fileprivate var willDelCodes = [CodeModel]()

    @ObservedObject var totpManager = TOTPManager.shared
    
    @State fileprivate var codeEditState = CodeEditState.dismiss
    @State fileprivate var codeQRState = CodeQRState.dismiss
    
    fileprivate var isCodeSelectAll: Bool {
        codeSelection.count == codes.count
    }
    
    @ViewBuilder
    fileprivate var leadingBarItems: some View {
        if isEditting {
            EmptyView()
        } else {
            Button(action: {
                self.isShowManageSheet = true
            }) {
                Image(systemName: "square.grid.2x2")
            }
            .padding([.trailing, .vertical], 15)
            .actionSheet(isPresented: $isShowAddSheet) { () -> ActionSheet in
                ActionSheet(title: Text("添加验证码"), message: nil, buttons: [
                    .default(Text("扫描二维码"), action: { self.isShowScanView = true }),
                    .default(Text("相册选择"), action: { self.isShowImgPickerView = true }),
                    .default(Text("手动输入"), action: { self.codeEditState = .add() }),
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
                self.codeSelection.removeAll()
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
    fileprivate var edittingView: some View {
        VStack {
            Divider()
            HStack(alignment: .center) {
                Button(action: {
                    if self.isCodeSelectAll {
                        self.codeSelection.removeAll()
                    } else {
                        self.codeSelection = Set(self.codes.map(\.id))
                    }
                }) { Text(isCodeSelectAll ? "全不选" : "全选").padding() }

                Spacer()
                Button(action: {
                    let items = self.codes.filter {
                        self.codeSelection.contains($0.id)
                    }
                    self.askDel(items: items)
                }) { Text("删除").padding() }
                .foregroundColor(codeSelection.isEmpty ? .gray : .red)
                .disabled(codeSelection.isEmpty)
            }
        }
    }
    fileprivate func cell(_ model: CodeModel) -> some View {
        let code = isEditting ? nil : self.totpManager.currentCode[model.secretKey ?? ""]
        let data = (model.account ?? "", model.secretKey ?? "", model.remark ?? "")
        let v = CodeCell(data: data, code: code?.displayCodeString ?? "--- ---")
        
        if isEditting {
            return AnyView(v).listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        
        return AnyView(
            v.contextMenu {
                Button(action: { self.copy(code: code) }) {
                    Text("复制")
                    Image(systemName: "doc.on.doc")
                }
                Button(action: { self.codeQRState = .show(code: model) }) {
                    Text("二维码")
                    Image(systemName: "qrcode")
                }
                Button(action: {
                    self.codeEditState = .edit(code: model)
                }) {
                    Text("编辑")
                    Image(systemName: "pencil")
                }
                Button(action: { self.askDel(items: [model]) }) {
                    Text("删除")
                    Image(systemName: "trash")
                }
            }
            // FIXME: - 点击右边空白处死活不触发, 只能点Text部分
            .onTapGesture {
                self.copy(code: code)
            }
            .sheet(isPresented: $codeQRState.isShow) {
                self.codeQRState.view
            }
        )
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    var codeView: some View {
        List(selection: $codeSelection) {
            ForEach(codes, id: \.id) { model in
                VStack(alignment: .leading, spacing: 0) {
                    self.cell(model)
                    Divider()
                }.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            .onMove { from, to in
                guard let f = from.last, f != to else {
                    return
                }
                self.moveCode(from: f, to: to)
            }
            .onDelete { item in
                self.askDel(items: item.map { self.codes[$0] })
            }
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(isEditting ? .active : .inactive))
        .modifier(ListSeparatorNoneViewModifier())
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
                    codeView
                } else {
                    Spacer()
                    Text(isEditting ? "暂无数据" : "点击右上角添加数据")
                }
                
                if codes.isEmpty {
                    Spacer()
                }
                
                if isEditting {
                    edittingView
                }
            }
            .edgesIgnoringSafeArea(isEditting ? .bottom : .init())
            .navigationBarTitle("验证码", displayMode: .inline)
            .navigationBarItems(leading: leadingBarItems, trailing: trailingBatItems)
        }
        .alert(isPresented: $isShowDelAlert, content: { () -> Alert in
            Alert(title: Text("删除后不可恢复, 是否删除?"), primaryButton: Alert.Button.destructive(Text("删除")) {
                self.realDel()
            }, secondaryButton: Alert.Button.default(Text("取消")))
        })
        .sheet(isPresented: $codeEditState.isShow) {
            self.codeEditState.view
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
                self.codeEditState = .add(params: ds)
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
    
    fileprivate func copy(code: Int?) {
        UIPasteboard.general.string = code?.codeString ?? ""
        HUD.showTextOnWin("复制成功")
    }
    
    fileprivate func moveCode(from: Int, to: Int) {
        if to == 0 {
            codes[from].score = codes[to].score - 4
        } else if to == codes.count {
            codes[from].score = codes[to - 1].score + 4
        } else {
            codes[from].score = (codes[to - 1].score + codes[to].score) / 2
        }
        
        do {
            try moc.save()
        } catch {
            HUD.showTextOnWin("操作失败, 数据库发生错误")
        }
    }
    
    fileprivate func askDel(items: [CodeModel]) {
        willDelCodes = items
        isShowDelAlert = true
    }
    
    fileprivate func realDel() {
        let objIDs = willDelCodes.map(\.objectID)
        willDelCodes.removeAll()
        let req = NSBatchDeleteRequest(objectIDs: objIDs)
        req.resultType = .resultTypeObjectIDs
        
        do {
            try moc.execute(req)
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objIDs], into: [moc])
        } catch {
            HUD.showTextOnWin("操作失败, 数据库发生错误")
        }
    }
}

struct CodeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return CodeView().environment(\.managedObjectContext, context)
    }
}
