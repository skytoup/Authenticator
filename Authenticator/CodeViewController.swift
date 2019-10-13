//
//  CodeViewController.swift
//  Authenticator
//
//  Created by skytoup on 2019/9/29.
//  Copyright © 2019 test. All rights reserved.
//

import CoreImage
import MobileCoreServices
import UIKit
import WatchConnectivity
import Result
import SnapKit
import ReactiveCocoa
import ReactiveSwift
import MBProgressHUD
import swiftScan

class CodeViewController: UIViewController {
    private let tbView = UITableView(frame: .zero, style: .plain)
    private lazy var dataSource = CodeTableViewDataSource(tbView: tbView, cmiDelegate: self)
    private var dataCount: Int {
        dataSource.tableView(tbView, numberOfRowsInSection: 0)
    }
    
    private let isSelectAll = MutableProperty<Bool>(false)
    private let timeProgressPip = Signal<Float, NoError>.pipe()
    
    override func loadView() {
        super.loadView()
        
        let sv = UIStackView(arrangedSubviews: [])
        let editSV = UIStackView(arrangedSubviews: [])
        let timeProgressView = UIProgressView(progressViewStyle: .default)
        let editSelectBtn = UIButton(type: .custom)
        let editDelBtn = UIButton(type: .custom)
        
        tbView.allowsSelection = true
        tbView.separatorStyle = .none
        tbView.register(CodeCell.self, forCellReuseIdentifier: "CodeCell")
        tbView.dataSource = dataSource
        tbView.delegate = self
        tbView.rowHeight = 97
        tbView.estimatedRowHeight = 97
        sv.axis = .vertical
        [tbView, editSV].forEach {
            sv.addArrangedSubview($0)
        }
        editSV.axis = .horizontal
        editSV.distribution = .equalCentering
        editSV.addArrangedSubview(editSelectBtn)
        editSV.addArrangedSubview(editDelBtn)
        editSV.isHidden = true
        editSelectBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 8)
        editSelectBtn.setTitle("全 选", for: .normal)
        editSelectBtn.setTitleColor(.label, for: .normal)
        editDelBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 32)
        editDelBtn.setTitle("删 除", for: .normal)
        editDelBtn.setTitleColor(.red, for: .normal)
        editDelBtn.setTitleColor(.gray, for: .disabled)
        editDelBtn.isEnabled = false
        
        [sv, timeProgressView].forEach {
            view.addSubview($0)
        }
        
        timeProgressView.snp.makeConstraints {
            $0.left.right.equalTo(0)
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
        }
        sv.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            $0.left.right.bottom.equalTo(0)
        }
        editSV.snp.makeConstraints {
            $0.height.equalTo(45)
        }
        
        let tbViewEditingSignal = tbView.reactive.signal(for: \.isEditing).skipRepeats()

        tbView.reactive.reloadData <~ Signal.merge(
            tbViewEditingSignal.map { _ in () },
            TOTPManager.share.updateCodeSignal
                .observe(on: QueueScheduler.main)
                .filter { [weak tbView] in return !(tbView?.isEditing ?? false) }
        )
        editSV.reactive.isHidden <~ tbViewEditingSignal.negate()

        editSelectBtn.reactive.controlEvents(.touchUpInside).throttle(0.5, on: QueueScheduler.main).observeValues { [weak self] _ in
            guard let ws = self else { return }

            let didSelectRow = ws.tbView.indexPathsForSelectedRows ?? []
            let allRow = (0..<ws.dataCount).map { IndexPath(row: $0, section: 0) }

            if ws.isSelectAll.value {
                allRow.filter {
                    didSelectRow.firstIndex(of: $0) != nil
                }.forEach {
                    ws.tbView.deselectRow(at: $0, animated: true)
                }
            } else {
                allRow.filter {
                    didSelectRow.firstIndex(of: $0) == nil
                }.forEach {
                    ws.tbView.selectRow(at: $0, animated: true, scrollPosition: .none)
                }
            }
        }
        dataSource.dataEditingDeleteSignal.observeValues {
            editDelBtn.isEnabled = false
        }
        let tbViewRowSelectSignal = Signal.merge(
            tbView.reactive.trigger(for: #selector(UITableView.selectRow(at:animated:scrollPosition:))),
            tbView.reactive.trigger(for: #selector(UITableView.deselectRow(at:animated:))),
            reactive.trigger(for: #selector(CodeViewController.tableView(_:didSelectRowAt:))),
            reactive.trigger(for: #selector(CodeViewController.tableView(_:didDeselectRowAt:)))
        )
        let tbViewRowSelectCountSignal = tbViewRowSelectSignal
            .filter { [weak tbView] in tbView?.isEditing ?? false }
            .map { [weak tbView] in tbView?.indexPathsForSelectedRows?.count ?? 0 }
        
        isSelectAll <~ tbViewRowSelectCountSignal.map { [weak self] in $0 == self?.dataCount ?? 0 }
        reactive.signal(for: #selector(CodeViewController.tableView(_:didSelectRowAt:)))
            .throttle(0.8, on: QueueScheduler.main)
            .map { ($0[0] as? UITableView, $0[1] as? IndexPath) }
            .filter { !($0.0?.isEditing ?? true) }
            .observeValues { [weak self] in
                guard let ws = self, let idx = $0.1, let model = ws.dataSource.itemIdentifier(for: idx) else { return }
                
                ws.copyCode(secretKey: model.secretKey)
                HUD.showText(ws.view, text: "复制成功")
                $0.0?.deselectRow(at: idx, animated: true)
            }
        editSelectBtn.reactive.title(for: .normal) <~ isSelectAll.skipRepeats().map { $0 ? "全不选" : "全 选" }
        editDelBtn.reactive.isEnabled <~ tbViewRowSelectCountSignal.map { $0 != 0 }
        editDelBtn.reactive.controlEvents(.touchUpInside)
            .throttle(0.5, on: QueueScheduler.main)
            .observeValues { [weak self] _ in
                guard let ws = self else { return }
                let models = (ws.tbView.indexPathsForSelectedRows ?? []).map {
                    ws.dataSource.itemIdentifier(for: $0)!
                }
                ws.delMulCodeModel(models: models)
            }
        
        let timeProgressPipInput = timeProgressPip.input
        let cellDataZeroSignal = dataSource.dataChangeSignal.skipRepeats().map { $0.count == 0 }
        let progressSignal = timeProgressPip.output.observe(on: QueueScheduler.main)
        timeProgressView.reactive.isHidden <~ cellDataZeroSignal
        timeProgressView.reactive.progress <~ progressSignal
        timeProgressView.reactive.tintColor <~ progressSignal
            .map { $0 <= 5 / 30 }
            .skipRepeats()
            .map { $0 ? UIColor.red : UIColor.blue }
        
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        timer.schedule(wallDeadline: DispatchWallTime.now(), repeating: 0.1)
        timer.setEventHandler { [weak timeProgressPipInput] in
            timeProgressPipInput?.send(value: 1 - Float(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 30)) / 30)
        }
        timer.resume()
        reactive.lifetime.observeEnded {
            timer.cancel()
        }
        var timerRunning = true
        cellDataZeroSignal.observeValues { [weak timer] in
            guard $0 == timerRunning, let wTimer = timer else {
                return
            }
            if $0 {
                wTimer.suspend()
            } else {
                wTimer.resume()
            }
            timerRunning = !$0
        }
        
        if WCSession.isSupported() {
            let wcs = WCSession.default
            wcs.delegate = self
            wcs.activate()
            dataSource.dataChangeSignal.skipRepeats().observeValues {
                let ds = $0.map {
                    $0.dictionaryWithValues(forKeys: ["account", "secretKey", "remark"])
                }
                try? wcs.updateApplicationContext(["datas": ds, "ver": "v1"])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        title = "验证码"
        
        let manageBtn = UIButton(type: .custom)
        let manageBtnItem = UIBarButtonItem(customView: manageBtn)
        let addBtn = UIButton(type: .custom)
        let addBtnItem = UIBarButtonItem(customView: addBtn)
        let editDoneBtn = UIButton(type: .custom)
        let editDoneBtnItem = UIBarButtonItem(customView: editDoneBtn)

        manageBtn.setTitle("管理", for: .normal)
        addBtn.setTitle("添加", for: .normal)
        editDoneBtn.setTitle("完成", for: .normal)
        [manageBtn, addBtn, editDoneBtn].forEach {
            $0.setTitleColor(.label, for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        navigationItem.leftBarButtonItem = manageBtnItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addBtn)
        
        addBtn.reactive.controlEvents(.touchUpInside).observeValues { [weak self] _ in
            self?.showAddCodeAlertController()
        }
        manageBtn.reactive.controlEvents(.touchUpInside).observeValues { [weak self] _ in
            self?.showManageAlertController()
        }
        let tbSwitchEditSignal = tbView.reactive.signal(for: \.isEditing)
            .skipRepeats()
            .sample(with: editDoneBtn.reactive.controlEvents(.touchUpInside))
            .throttle(0.5, on: QueueScheduler.main)
            .map { $0.0 }
            .negate()
        tbView.reactive.makeBindingTarget { $0.isEditing = $1 } <~ tbSwitchEditSignal
        tbView.allowsMultipleSelectionDuringEditing = true
        
        tbView.reactive.signal(for: \.isEditing)
            .skipRepeats()
            .observeValues { [weak self] in
                guard let ws = self else { return }
                if $0 {
                    ws.navigationItem.leftBarButtonItem = nil
                    ws.navigationItem.rightBarButtonItem = editDoneBtnItem
                } else {
                    ws.navigationItem.leftBarButtonItem = manageBtnItem
                    ws.navigationItem.rightBarButtonItem = addBtnItem
                }
            }
    }
    
    // MARK: - private
    private func copyCode(secretKey: String) {
        let code = TOTPManager.share.codeFrom(secretKey: secretKey)
        UIPasteboard.general.string = String(format: "%06d", code ?? 0)
    }
    private func makeCellContextMenu(model: AuthModel) -> UIMenu {
        return UIMenu(title: "", children: [
            UIAction(title: "复 制", handler: { [weak self] _ in
                guard let ws = self else { return }
                ws.copyCode(secretKey: model.secretKey)
                HUD.showText(ws.view, text: "复制成功")
            }),
            UIAction(title: "二维码", handler: { [weak self] _ in
                self?.present(UINavigationController(rootViewController: CodeQRViewController(model: model)), animated: true, completion: nil)
            }),
            UIAction(title: "编 辑", handler: { [weak self] _ in
                self?.editCodeModel(model)
            }),
            UIAction(title: "删 除", attributes: .destructive, handler: { [weak self] _ in
                self?.delCodeModel(model)
            })
        ])
    }
    private func cellSwipeActionsConfiguration(indexPath: IndexPath) -> UISwipeActionsConfiguration {
        return UISwipeActionsConfiguration(actions: [
            UIContextualAction(style: .normal, title: "编辑", handler: { [weak self] (_, _, actionPerformed) in
                guard let ws = self, let model = ws.dataSource.itemIdentifier(for: indexPath) else {
                    actionPerformed(false)
                    return
                }
                ws.editCodeModel(model)
                actionPerformed(true)
            }),
            UIContextualAction(style: .destructive, title: "删除", handler: { [weak self] (_, _, actionPerformed) in
                guard let ws = self, let model = ws.dataSource.itemIdentifier(for: indexPath) else {
                    actionPerformed(false)
                    return
                }
                
                ws.delCodeModel(model)
                actionPerformed(true)
            })
        ])
    }
    private func showEditVC(_ vc: CodeEditViewController) {
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    private func showEditFromQRStr(_ qrStr: String) {
        do {
            let ds = try TOTP.parseURL(qrStr)
            DispatchQueue.main.async { [weak self] in
                self?.showEditVC(CodeEditViewController(type: .add(account: ds.issuer, secretKey: ds.secretKey, remark: ds.remark)))
            }
        } catch let error as TOTP.ParseError {
            switch error {
            case .URL:
                HUD.showText(view, text: "解析链接错误")
            case .secretKey:
                HUD.showText(view, text: "解析秘钥错误")
            case .type:
                HUD.showText(view, text: "只支持TOTP(基于时间点的验证)")
            }
        } catch {
            HUD.showText(view, text: "解析错误")
        }
    }
    private func showEditFromQR(_ ciImg: CIImage) {
        let hud = HUD.showWaitText(view, text: "识别中...")
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            defer {
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                }
            }
            guard let ws = self else { return }
            
            guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow]), let features = detector.features(in: ciImg) as? [CIQRCodeFeature] else {
                HUD.showText(ws.view, text: "系统不支持识别二维码")
                return
            }
            guard features.count > 0, let qrStr = features.first?.messageString else {
                HUD.showText(ws.view, text: "识别二维码失败")
                return
            }
            
            ws.showEditFromQRStr(qrStr)
        }
    }
    private func showAddCodeAlertController() {
        let ac = UIAlertController(title: "添加验证码", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "扫描二维码", style: .default, handler: { [weak self] _ in
            self?.showScanQRController()
        }))
        ac.addAction(UIAlertAction(title: "相册选择", style: .default, handler: { [weak self] _ in
            self?.showPhotoController()
        }))
        ac.addAction(UIAlertAction(title: "手动填写", style: .default, handler: { [weak self] _ in
            self?.manualAddModel()
        }))
        ac.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }
    private func showScanQRController() {
        let scanVC = LBXScanViewController()
        scanVC.arrayCodeType = [.qr]
        scanVC.scanResultDelegate = self
        let style = LBXScanViewStyle()
        scanVC.scanStyle = style
        scanVC.title = "扫描二维码"
        navigationController?.pushViewController(scanVC, animated: true)
    }
    private func showPhotoController() {
        let ipc = UIImagePickerController()
        ipc.allowsEditing = false
        ipc.mediaTypes = [kUTTypeImage as String]
        ipc.sourceType = .photoLibrary
        ipc.delegate = self
        present(ipc, animated: true, completion: nil)
    }
    private func showManageAlertController() {
        let ac = UIAlertController(title: "管理", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "编辑", style: .default, handler: { [weak self] _ in
            self?.beginEditCode()
        }))
        ac.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }
    private func beginEditCode() {
        tbView.allowsMultipleSelectionDuringEditing = true
        tbView.isEditing = true
    }
    private func manualAddModel() {
        showEditVC(CodeEditViewController(type: .add(account: "", secretKey: "", remark: "")))
    }
    private func delMulCodeModel(models: [AuthModel]) {
        guard models.count != 0 else { return }
        let msg: String
        if models.count == 1 {
            let model = models.first!
            msg = "是否删除 \(model.account)(\(model.remark))"
        } else {
            msg = "是否删除选中的多个验证码"
        }
        let ac = UIAlertController(title: "提示", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in
            try? RealmDB.share.db?.write {
                models.forEach {
                    RealmDB.share.db?.delete($0)
                }
            }
        }))
        present(ac, animated: true, completion: nil)
    }
    private func delCodeModel(_ model: AuthModel) {
        delMulCodeModel(models: [model])
    }
    private func editCodeModel(_ model: AuthModel) {
        showEditVC(CodeEditViewController(type: .edit(model)))
    }
}

// MARK: - UITableViewDelegate
extension CodeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) { }
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        tableView.isEditing = true
        return true
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return cellSwipeActionsConfiguration(indexPath: indexPath)
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension CodeViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard !tbView.isEditing, let realLocation = interaction.view?.convert(location, to: tbView), let idx = tbView.indexPathForRow(at: realLocation), let model = dataSource.itemIdentifier(for: idx) else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ -> UIMenu? in
            return self?.makeCellContextMenu(model: model)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let img = info[.originalImage] as? UIImage, let cgImg = img.cgImage else {
            HUD.showText(view, text: "获取图片失败")
            return
        }
        let ciImg = CIImage(cgImage: cgImg)
        showEditFromQR(ciImg)
    }
}

// MARK: - LBXScanViewControllerDelegate
extension CodeViewController: LBXScanViewControllerDelegate {
    func scanFinished(scanResult: LBXScanResult, error: String?) {
        guard let qrStr = scanResult.strScanned else {
            HUD.showText(view, text: "扫描失败")
            return
        }
        
        showEditFromQRStr(qrStr)
    }
}

extension CodeViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }
}
