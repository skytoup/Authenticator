//
//  CodeInterfaceController.swift
//  Watch Extension
//
//  Created by skytoup on 2019/10/10.
//  Copyright © 2019 test. All rights reserved.
//

import WatchKit
import Foundation
import Result
import ReactiveCocoa
import ReactiveSwift
import WatchConnectivity

//typealias CodeData = (account: String, secretKey: String, remark: String?)

class CodeInterfaceController: WKInterfaceController {
    private static let dataKey = "__code_datas__"
    
    @IBOutlet weak var contentGV: WKInterfaceGroup!
    @IBOutlet weak var tipGV: WKInterfaceGroup!
    @IBOutlet weak var tbView: WKInterfaceTable!
    @IBOutlet weak var progressLb: WKInterfaceLabel!
    
    private let timeProgressPip = Signal<Int, NoError>.pipe()
    
    private let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
    private var timerRunning = false
    
    var items: [TOTP.Params] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        reciveDatas()
        loadDatas()
        reloadRow()
        setupReactive()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if !timerRunning && items.count > 0 {
            timer.resume()
            timerRunning = true
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        if timerRunning {
            timer.suspend()
            timerRunning = false
        }
    }

    // MARK: - private
    private func reciveDatas() {
        let wcs = WCSession.default
        wcs.delegate = self
        wcs.activate()
    }
    private func loadDatas() {
        guard let ds = UserDefaults.standard.dictionary(forKey: CodeInterfaceController.dataKey)?["datas"] as? [[String:String]] else {
            return
        }
        items = ds.reduce(into: [TOTP.Params](), {
            $0.append((
                $1["account"] ?? "",
                $1["secretKey"] ?? "",
                $1["remark"] ?? ""
            ))
        })
        tbView.setNumberOfRows(items.count, withRowType: "CodeRow")
        
        let hasDatas = items.count > 0
        contentGV.setHidden(!hasDatas)
        tipGV.setHidden(hasDatas)
        if hasDatas && !timerRunning {
            timerRunning = true
            timer.resume()
        } else if !hasDatas && timerRunning {
            timerRunning = false
            timer.suspend()
        }
    }
    private func reloadRow() {
        items.enumerated().forEach {
            guard let rc = tbView.rowController(at: $0) as? CodeRow else {
                return
            }
            let code = TOTP.genCode(secretKey: $1.secretKey)?.codeString ?? "--- ---"
            rc.accountLb.setText("\($1.issuer)")
            rc.codeLb.setText("\(code)")
            let hasRemark = $1.remark.count != 0
            rc.remarkLb.setText("\(hasRemark ? $1.remark : "备注")")
            rc.remarkLb.setTextColor(hasRemark ? .white : .gray )
        }
    }
    private func setupReactive() {
        let timeProgressPipInput = timeProgressPip.input
        
        timer.schedule(wallDeadline: DispatchWallTime.now(), repeating: 0.1)
        timer.setEventHandler { [weak timeProgressPipInput] in
            timeProgressPipInput?.send(value: 30 - Int(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 30)))
        }
        reactive.lifetime.observeEnded { [weak self] in self?.timer.cancel() }
        
        timeProgressPip.output.observeValues { [weak self] in self?.progressLb.setText("\($0)秒后刷新") }
        progressLb.reactive.makeBindingTarget { $0.setTextColor($1) } <~ timeProgressPip.output.map {
            $0 <= 5 ? UIColor.red : UIColor.white
        }
        TOTPManager.share.updateCodeSignal.observeValues { [weak self] in self?.reloadRow() }
    }
}

extension CodeInterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let _ = applicationContext["datas"] as? [[String: String]], let ver = applicationContext["ver"] as? String else {
            return
        }
        guard ver == "v1" else {
            return
        }
        
        UserDefaults.standard.set(applicationContext, forKey: CodeInterfaceController.dataKey)
        
        loadDatas()
        reloadRow()
    }
    
}
