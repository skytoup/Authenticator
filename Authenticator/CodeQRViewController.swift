//
//  CodeQRViewController.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/7.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit

class CodeQRViewController: UIViewController {

    var model: AuthModel
    
    init(model: AuthModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        let accountLb = UILabel()
        let remarkLb = UILabel()
        let qrImg = UIImageView()
        let saveBtn = UIButton(type: .custom)
        let sv = UIStackView(arrangedSubviews: [
            qrImg,
            accountLb,
            remarkLb,
            saveBtn
        ])
        
        accountLb.text = model.account
        accountLb.textAlignment = .center
        remarkLb.text = model.remark
        remarkLb.textAlignment = .center
        qrImg.contentMode = .scaleAspectFit
        saveBtn.setTitle("保存二维码", for: .normal)
        saveBtn.setTitleColor(.label, for: .normal)
        saveBtn.setTitleColor(.placeholderText, for: .disabled)
        saveBtn.isEnabled = false
        sv.axis = .vertical
        sv.spacing = 8
        sv.setCustomSpacing(15, after: remarkLb)
        
        view.addSubview(sv)
        
        sv.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(8)
            $0.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            $0.left.equalTo(8)
            $0.right.equalTo(-8)
        }
        
        saveBtn.reactive.controlEvents(.touchUpInside).observeValues { [weak self] _ in
            guard let ws = self else { return }
            guard let img = qrImg.image else {
                HUD.showText(ws.view, text: "保存二维码失败")
                return
            }
            UIImageWriteToSavedPhotosAlbum(img, self, #selector(CodeQRViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        let urlStr = TOTP.genURL((model.account, model.secretKey, model.remark))
        let hud = HUD.showWaitText(view, text: "正在创建二维码...")
        genQRImg(str: urlStr) {
            hud.hide(animated: true)
            if $0 != nil {
                qrImg.image = $0
                saveBtn.isEnabled = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "验证码二维码"
        view.backgroundColor = .systemBackground
        
        let doneBtn = UIButton(type: .custom)
        doneBtn.setTitle("完成", for: .normal)
        doneBtn.setTitleColor(.label, for: .normal)
        doneBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneBtn)
        
        doneBtn.reactive.controlEvents(.touchUpInside).observeValues { [weak self] _ in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - private
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        HUD.showText(view, text: error == nil ? "保存成功" : "保存失败")
    }
    private func genQRImg(str: String, complateBlock: @escaping @convention(block) (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let ws = self else { return }
            guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
                HUD.showText(ws.view, text: "系统不支持创建二维码")
                complateBlock(nil)
                return
            }
            filter.setDefaults()
            let data = str.data(using: .utf8)
            filter.setValue(data, forKey: "inputMessage")

            guard let ciImg = filter.outputImage else {
                HUD.showText(ws.view, text: "创建二维码失败")
                complateBlock(nil)
                return
            }
            
            let size = UIScreen.main.bounds.width
            let sCIImage = ciImg.transformed(by: CGAffineTransform(scaleX: size/ciImg.extent.width, y: size/ciImg.extent.height))
            guard let cgImg = CIContext().createCGImage(sCIImage, from: sCIImage.extent) else {
                HUD.showText(ws.view, text: "创建二维码失败")
                complateBlock(nil)
                return
            }
            
            DispatchQueue.main.async {
                complateBlock(UIImage(cgImage: cgImg))
            }
        }
    }
}
