//
//  CodeEditView.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/21.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import CoreData

struct CodeEditView: View {
    // MARK: - view
    var body: some View {
        NavigationView {
            VStack {
                Spacer().frame(height: 15)
                ForEach([
                    ("账 号", "必填, 50字符内", $account),
                    ("秘 钥", "必填, 128字符内", $secretKey),
                    ("备 注", "可空, 50字符内", $remark),
                ], id: \.0) { ds in
                    VStack(alignment: .leading) {
                        Text(ds.0)
                            .font(.system(size: 20, weight: .bold))
                        MarkedTextField(ds.1, text: ds.2)
                    }
                    .padding(.horizontal, 15)
                }
                
                VStack(alignment: .center) {
                    Button(action: { self.saveOrAdd() }) {
                        Text(isAddModel ? "添 加" : "保 存")
                            .font(.system(size: 18))
                    }
                    .disabled(!isCanSaveOrAdd)
                    .padding()
                }
                Spacer()
            }
            .navigationBarTitle(isAddModel ? "添加验证码" : "编辑验证码", displayMode: .inline)
            .navigationBarItems(leading: leadingBarItems)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    fileprivate var leadingBarItems: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) { Text("取消") }
            .padding([.vertical, .trailing], 20)
    }
    
    // MARK: - property
    @Environment(\.managedObjectContext) fileprivate var moc
    @Environment(\.presentationMode) fileprivate var presentationMode
    
    @State fileprivate var account: String
    @State fileprivate var secretKey: String
    @State fileprivate var remark: String
    
    fileprivate let code: CodeModel?
    fileprivate var isAddModel: Bool { code == nil }
    
    init(code: CodeModel) {
        self.code = code
        _account = .init(initialValue: code.account ?? "")
        _secretKey = .init(initialValue: code.secretKey ?? "")
        _remark = .init(initialValue: code.remark ?? "")
    }
    
    init(params: TOTP.Params? = nil) {
        self.code = nil
        _account = .init(initialValue: params?.issuer ?? "")
        _secretKey = .init(initialValue: params?.secretKey ?? "")
        _remark = .init(initialValue: params?.remark ?? "")
    }
    
    fileprivate var isCanSaveOrAdd: Bool {
        let base32CharSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        guard (1...50).contains(account.count),
            (1...128).contains(secretKey.count),
            (0...50).contains(remark.count),
            base32CharSet.isSuperset(of: CharacterSet(charactersIn: secretKey.uppercased())) else {
            return false
        }
        return true
    }
    
    fileprivate func checkSecretKeyIsExist() throws -> Bool {
        let fReq = NSFetchRequest<CodeModel>(entityName: CodeModel.name)
        fReq.predicate = NSPredicate(format: "secretKey == %@", secretKey)
        return try moc.count(for: fReq) != 0
    }
    
    fileprivate func saveOrAdd() {
        do {
            if let code = code {
                if code.secretKey != secretKey.uppercased() {
                    guard !(try checkSecretKeyIsExist()) else {
                        HUD.showTextOnWin("该秘钥已存在")
                        return
                    }
                    code.secretKey = secretKey.uppercased()
                }
                code.id = UUID()
                code.account = account
                code.remark = remark
            } else {
                guard !(try checkSecretKeyIsExist()) else {
                    HUD.showTextOnWin("该秘钥已存在")
                    return
                }
                
                let fReq = NSFetchRequest<CodeModel>(entityName: CodeModel.name)
                fReq.sortDescriptors = [NSSortDescriptor(keyPath: \CodeModel.score, ascending: false)]
                fReq.fetchLimit = 1
                let fRes = try moc.fetch(fReq)

                let m = CodeModel(context: moc)
                m.id = UUID()
                m.account = account
                m.secretKey = secretKey
                m.remark = remark
                m.score = (fRes.last?.score ?? 10) + 4
            }
            try moc.save()
            
            self.presentationMode.wrappedValue.dismiss()
        } catch {
            HUD.showTextOnWin("操作失败, 数据库发生错误")
        }
    }
    
}

struct CodeEditView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return CodeEditView().environment(\.managedObjectContext, context)
    }
}
