//
//  CodeEditViewController.swift
//  Authenticator
//
//  Created by skytoup on 2019/9/29.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit
import ReactiveSwift

class CodeEditViewController: UIViewController {
    // 操作类型
    enum EditType {
        case add(account: String, secretKey: String, remark: String) // 添加
        case edit(AuthModel) // 编辑
    }

    var type: EditType
    
    var vcTitle: String {
        switch self.type {
        case .add:
            return "新增验证码"
        case .edit:
            return "编辑验证码"
        }
    }
    var addBtnTitle: String {
        switch self.type {
        case .add:
            return "添 加"
        case .edit:
            return "保 存"
        }
    }
    var doneSuccessMsg: String {
        switch self.type {
        case .add:
            return "添加成功"
        case .edit:
            return "保存成功"
        }
    }
    
    init(type: EditType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        let accountLb = UILabel()
        let accountTF = UITextField()
        let secretKeyLb = UILabel()
        let secretKeyTF = UITextField()
        let remarkLb = UILabel()
        let remarkTF = UITextField()
        let doneBtn = UIButton()
        let stv = UIStackView(arrangedSubviews: [accountLb, accountTF, secretKeyLb, secretKeyTF, remarkLb, remarkTF, doneBtn])
        let tfs = [accountTF, secretKeyTF, remarkTF]
        
        accountLb.text = "账 号"
        accountTF.placeholder = "必填, 50字符内"
        secretKeyLb.text = "秘 钥"
        secretKeyTF.placeholder = "必填, 128字符内"
        remarkLb.text = "备 注"
        remarkTF.placeholder = "可空, 50字符内"
        if case let .edit(model) = type {
            accountTF.text = model.account
            secretKeyTF.text = model.secretKey
            remarkTF.text = model.remark
        } else if case let .add(account, secretKey, remark) = type {
            accountTF.text = account
            secretKeyTF.text = secretKey
            remarkTF.text = remark
        }
        doneBtn.setTitle(addBtnTitle, for: .normal)
        doneBtn.setTitleColor(.label, for: .normal)
        doneBtn.setTitleColor(.placeholderText, for: .disabled)
        doneBtn.isEnabled = false
        tfs.forEach {
            $0.clearButtonMode = .whileEditing
            $0.returnKeyType = .next
            $0.borderStyle = .roundedRect
            stv.setCustomSpacing(8, after: $0)
        }
        remarkTF.returnKeyType = .done
        stv.axis = .vertical
        stv.spacing = 3

        view.addSubview(stv)
        
        stv.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(8)
            $0.left.equalTo(8)
            $0.right.equalTo(-8)
            $0.width.equalToSuperview().offset(-16)
        }
        doneBtn.snp.makeConstraints {
            $0.centerX.equalToSuperview()
        }
        
        tfs.forEach {
            $0.reactive.controlEvents(.editingDidEndOnExit).observe {
                guard let idx = tfs.firstIndex(of: $0.value!) else { return }
                
                let isLast = tfs.count - 1 == idx
                if isLast {
                    $0.value?.resignFirstResponder()
                } else {
                    tfs[idx + 1].becomeFirstResponder()
                }
            }
        }
        
        let accountSignal = accountTF.reactive.continuousTextValues
        let secretKeySignal = secretKeyTF.reactive.continuousTextValues
        let remarkSignal = remarkTF.reactive.continuousTextValues
        
        doneBtn.reactive.isEnabled <~ Signal.combineLatest(
            accountSignal.countInRange(range: 1...50),
            secretKeySignal.countInRange(range: 1...128),
            remarkSignal.countInRange(range: 0...50)
        ).throttle(0.5, on: QueueScheduler.main).map {
            $0 && $1 && $2
        }
        
        reactive.isModalInPresentation <~ Signal.merge(
            accountSignal,
            secretKeySignal,
            remarkSignal
        )
        .throttle(0.5, on: QueueScheduler.main)
        .map { [weak self] _ in
            guard let ws = self else { return false }
            switch ws.type {
            case .add:
                return accountTF.text?.count ?? 0 > 0 || secretKeyTF.text?.count ?? 0 > 0 || remarkTF.text?.count ?? 0 > 0
            case .edit(let model):
                return (model.account, model.secretKey, model.remark) != (accountTF.text ?? "", secretKeyTF.text ?? "", remarkTF.text ?? "")
            }
        }
        
        Signal.combineLatest(
            accountSignal,
            secretKeySignal,
            remarkSignal
        )
        .sample(with: doneBtn.reactive.controlEvents(.touchUpInside))
        .throttle(0.5, on: QueueScheduler.main)
        .observeValues { [weak self] data, _ in
            guard let ws = self else { return }
            guard let _ = data.1.base32Decode() else {
                HUD.showText(ws.view, text: "秘钥错误")
                return
            }

            switch ws.type {
            case .add:
                guard ws.addModel(params: data) else {
                    return
                }
            case .edit(let model):
                guard ws.save(new: data, to: model) else {
                    return
                }
            }
            
            HUD.showText(ws.view, text: ws.doneSuccessMsg)
            ws.navigationController?.dismiss(animated: true, completion: nil)
        }
        
        accountTF.sendActions(for: .editingDidEnd)
        secretKeyTF.sendActions(for: .editingDidEnd)
        remarkTF.sendActions(for: .editingDidEnd)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = vcTitle
        view.backgroundColor = .systemBackground
        navigationController?.presentationController?.delegate = self

        let cancelBtn = UIButton(type: .custom)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(.label, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelBtn)
        cancelBtn.reactive.controlEvents(.touchUpInside).observe { [weak self] _ in
            guard let ws = self else { return }
            if ws.isModalInPresentation {
                ws.confirmCancel()
            } else {
                ws.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
    }

    // MARK: - private
    private func addModel(params: TOTP.Params) -> Bool {
        guard RealmDB.share.db?.objects(AuthModel.self).filter(NSPredicate(format: "secretKey = %@", params.secretKey)).count == 0 else {
            HUD.showText(view, text: "秘钥已存在")
            return false
        }
        
        let model = AuthModel(value: [
            "account": params.issuer,
            "secretKey": params.secretKey,
            "remark": params.remark,
            "score": (RealmDB.share.db?.objects(AuthModel.self).sorted(byKeyPath: "score").last?.score ?? 0) + 1
        ])
        try? RealmDB.share.db?.write {
            RealmDB.share.db?.add(model)
        }
        return true
    }
    private func save(new params: TOTP.Params, to model: AuthModel) -> Bool {
        if params.secretKey != model.secretKey && RealmDB.share.db?.objects(AuthModel.self).filter(NSPredicate(format: "secretKey = %@",  params.secretKey)).count != 0 {
            HUD.showText(view, text: "秘钥已存在")
            return false
        }

        try? RealmDB.share.db?.write {
            model.account = params.issuer
            model.secretKey = params.secretKey
            model.remark = params.remark
        }
        return true
    }
    private func confirmCancel() {
        let ac = UIAlertController(title: "提示", message: "尚未保存, 是否离开?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "留下", style: .default, handler: nil))
        ac.addAction(UIAlertAction(title: "不保存", style: .destructive, handler: { [weak self] _ in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }))
        present(ac, animated: true, completion: nil)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension CodeEditViewController : UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        confirmCancel()
    }
}
