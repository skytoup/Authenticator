//
//  HUD.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/6.
//  Copyright © 2019 test. All rights reserved.
//

import MBProgressHUD

class HUD {
    static func showTextOnWin(_ text: String, time: TimeInterval = 2) {
        guard let win = UIApplication.shared.windows.first else {
            return
        }
        Self.showText(win, text: text, time: time)
    }
    static func showWaitTextOnWin(_ text: String, time: TimeInterval = 2) -> MBProgressHUD? {
        guard let win = UIApplication.shared.windows.first else {
            return nil
        }
        return Self.showWaitText(win, text: text)
    }
    
    static func showText(_ view: UIView, text: String, time: TimeInterval = 2) {
        SafeDispatch.syncMain {
            let hud = _hud(view)
            hud.mode = .text
            hud.label.text = text
            hud.isUserInteractionEnabled = false
            hud.hide(animated: true, afterDelay: time)
        }
    }
    
    static func showWaitText(_ view: UIView, text: String) -> MBProgressHUD {
        var hud: MBProgressHUD!
        SafeDispatch.syncMain {
            hud = _hud(view)
            hud.mode = .indeterminate
            hud.label.text = text
            hud.isUserInteractionEnabled = true
        }
        return hud
    }
    
    private static func _hud(_ view: UIView) -> MBProgressHUD {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.animationType = .fade
        hud.graceTime = 0.8
        hud.minShowTime = 0.8
        return hud
    }
}
