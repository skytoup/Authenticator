//
//  CodeList.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/28.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import CoreData

struct CodeList: View {
    // MARK: - view
    @ViewBuilder
    var body: some View {
        if codes.isEmpty {
            Spacer()
            if kw.isEmpty {
                Text(isEditting ? "暂无数据" : "点击右上角添加数据")
            } else {
                Text("无符合的搜索数据")
            }
        } else {
            List(selection: $codeSelection) {
                if isEditting && !self.kw.isEmpty {
                    Text("Tips: 搜索时不能排序")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                listContent()
            }
            .listStyle(PlainListStyle())
            .modifier(ListSeparatorNoneViewModifier())
            .environment(\.editMode, .constant(isEditting ? .active : .inactive))
            .alert(isPresented: $isShowDelAlert, content: { () -> Alert in
                Alert(title: Text("删除后不可恢复, 是否删除?"), primaryButton: Alert.Button.destructive(Text("删除")) {
                    self.realDel()
                }, secondaryButton: Alert.Button.default(Text("取消")))
            })
            .sheet(isPresented: $codeEditShowState.isShow) {
                self.codeEditShowState.view
                    .environment(\.managedObjectContext, self.moc)
            }
        }
        
        if codes.isEmpty {
            Spacer()
        }
        
        if isEditting {
            edittingView
                .transition(.move(edge: .bottom))
                .animation(.easeInOut)
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
        .onDisappear {
            self.codeSelection.removeAll()
        }
    }
    fileprivate func cell(_ model: CodeModel) -> some View {
        let code = isEditting ? nil : self.totpManager.currentCode[model.secretKey ?? ""]
        let data = (model.account ?? "", model.secretKey ?? "", model.remark ?? "")
        let v = CodeCell(data: data, code: code?.displayCodeString ?? "--- ---", isRefreshSoon: isRefreshSoon)
        
        if isEditting {
            return AnyView(v).listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        
        return AnyView(
            v.contextMenu {
                Button(action: { self.copy(code: code) }) {
                    Text("复制")
                    Image(systemName: "doc.on.doc")
                }
                Button(action: { self.codeQRShowState = .show(code: model) }) {
                    Text("二维码")
                    Image(systemName: "qrcode")
                }
                Button(action: {
                    self.codeEditShowState = .edit(code: model)
                }) {
                    Text("编辑")
                    Image(systemName: "pencil")
                }
                Button(action: { self.askDel(items: [model]) }) {
                    Text("删除")
                    Image(systemName: "trash")
                }
            }
            // NOTE: - 点击右边空白处死活不触发, 只能点Text部分, 13.4又出现这问题, 加了这个可以修复
            .contentShape(Rectangle())
            .onTapGesture {
                self.copy(code: code)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            .sheet(isPresented: $codeQRShowState.isShow) {
                self.codeQRShowState.view
            }
        )
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    func listContent() -> some View {
        ForEach(codeFR.wrappedValue, id: \.id) { model in
            VStack(alignment: .leading, spacing: 0) {
                self.cell(model)
                Divider()
            }.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }.onMove { from, to in
            guard let f = from.last, f != to else {
                return
            }
            self.moveCode(from: f, to: to)
        }
        .onDelete { item in
            self.askDel(items: item.map { self.codes[$0] })
        }
        .moveDisabled(!self.kw.isEmpty)
    }
    
    // MARK: - property
    @Environment(\.managedObjectContext) fileprivate var moc
    @ObservedObject fileprivate var totpManager = TOTPManager.shared
    
    @Binding fileprivate var isEditting: Bool
    @Binding fileprivate var isRefreshSoon: Bool
    @Binding fileprivate var kw: String
    
    @State fileprivate var isShowDelAlert = false
    @State fileprivate var willDelCodes = [CodeModel]()
    @State fileprivate var codeSelection = Set<UUID?>()
    
    @State fileprivate var codeQRShowState = CodeQRShowState.dismiss
    @State fileprivate var codeEditShowState = CodeEditShowState.dismiss
    
    
    fileprivate var isCodeSelectAll: Bool {
        codeSelection.count == codeFR.wrappedValue.count
    }
    fileprivate var codes: FetchedResults<CodeModel> { codeFR.wrappedValue }
    fileprivate var codeFR: FetchRequest<CodeModel>
    
    init(kw: Binding<String>, isEditting: Binding<Bool>, isRefreshSoon: Binding<Bool>) {
        self._kw = kw
        _isEditting = isEditting
        _isRefreshSoon = isRefreshSoon
        
        let _kw = kw.wrappedValue
        let predicate = kw.wrappedValue.isEmpty ? nil : NSPredicate(format: "account CONTAINS[cd] %@ OR remark CONTAINS[cd] %@", _kw, _kw)
        codeFR = FetchRequest(entity: CodeModel.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CodeModel.score, ascending: true)], predicate: predicate)
    }
    
    fileprivate func copy(code: Int?) {
        UIPasteboard.general.string = code?.codeString ?? ""
        HUD.showTextOnWin("复制成功")
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
    
}

struct CodeList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CodeList(kw: .constant(""), isEditting: .constant(false), isRefreshSoon: .constant(false))
                .previewDisplayName("非编辑状态")
            CodeList(kw: .constant(""), isEditting: .constant(true), isRefreshSoon: .constant(false))
                .previewDisplayName("编辑状态")
        }
    }
}
