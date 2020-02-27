//
//  LBXScan.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/26.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import swiftScan

struct LBXScan: UIViewControllerRepresentable {
    typealias ScanFinishedHandler = ((_ qrStr: String) -> Void)

    @Binding var isShow: Bool

    let finishedHandler: ScanFinishedHandler?
    
    class Coordinator: LBXScanViewControllerDelegate {
        var isShow: Binding<Bool>
        let finishedHandler: ScanFinishedHandler?
        
        init(isShow: Binding<Bool>, finished handler: ScanFinishedHandler?) {
            self.finishedHandler = handler
            self.isShow = isShow
        }
        
        func scanFinished(scanResult: LBXScanResult, error: String?) {
            guard let qrStr = scanResult.strScanned else {
                HUD.showTextOnWin("扫描失败")
                return
            }
            
            isShow.wrappedValue = false
            finishedHandler?(qrStr)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isShow: $isShow, finished: finishedHandler)
    }
    func makeUIViewController(context: Context) -> LBXScanViewController {
        let svc = LBXScanViewController()
        svc.arrayCodeType = [.qr]
        svc.scanResultDelegate = context.coordinator
        let style = LBXScanViewStyle()
        svc.scanStyle = style
        return svc
    }
    func updateUIViewController(_ uiViewController: LBXScanViewController, context: Context) {
        
    }
}
