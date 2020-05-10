//
//  CodeQRView.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/26.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct CodeQRView: View {
    // MARK: - view
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                if qrImg == nil {
                     Text("加载中...")
                } else {
                    Image(uiImage: qrImg!).resizable().aspectRatio(contentMode: .fit).padding()
                }
                
                Spacer()
                
                VStack(spacing: 5) {
                    Text(code.account ?? "")
                    if !(code.remark?.isEmpty ?? true) {
                        Text(code.remark!)
                    }
                }
                
                Button(action: {
                    self.saveQRImg()
                }) { Text("保存二维码") }
                    .padding()
                    .disabled(qrImg == nil)
            }
            .navigationBarItems(trailing: trailingBarItems)
            .navigationBarTitle("验证码二维码", displayMode: .inline)
            .onAppear {
                let code = self.code
                let urlStr = TOTP.genURL((code.account ?? "", code.secretKey ?? "", code.remark ?? ""))
                self.genQRImg(str: urlStr)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    fileprivate var trailingBarItems: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) { Text("关闭") }
        .padding([.vertical, .leading], 20)
    }
    
    // MARK: - property
    
    @Environment(\.presentationMode) fileprivate var presentationMode
    
    @State fileprivate var qrImg: UIImage?
    
    let code: CodeModel
    
    fileprivate func saveQRImg() {
        guard let img = qrImg else {
            HUD.showTextOnWin("保存二维码失败")
            return
        }
        
        let saver = ImgSaver()
        saver.complationHandler = { res in
            if case .success = res {
                HUD.showTextOnWin("保存成功")
            } else {
                HUD.showTextOnWin("保存失败")
            }
        }
        saver.saveToPhotoAlbum(image: img)
    }
    
    fileprivate func genQRImg(str: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
                HUD.showTextOnWin("系统不支持创建二维码")
                return
            }
            filter.setDefaults()
            let data = str.data(using: .utf8)
            filter.setValue(data, forKey: "inputMessage")

            guard let ciImg = filter.outputImage else {
                HUD.showTextOnWin("创建二维码失败")
                return
            }
            
            // 放大图片
            let size = UIScreen.main.bounds.width
            let sCIImage = ciImg.transformed(by: CGAffineTransform(scaleX: size/ciImg.extent.width, y: size/ciImg.extent.height))
            // 转存CGImage, 不然保存相册会失败(虽然没有Error, 但是没有保存图片)
            guard let cgImg = CIContext().createCGImage(sCIImage, from: sCIImage.extent) else {
                HUD.showTextOnWin("创建二维码失败")
                return
            }
            
            DispatchQueue.main.async {
                self.qrImg = UIImage(cgImage: cgImg)
            }
        }
    }

}

struct CodeQRView_Previews: PreviewProvider {
    static var previews: some View {
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let code = CodeModel(context: moc)
        code.account = "account test"
        code.secretKey = "234"
        code.remark = "remark test"
        return CodeQRView(code: code)
    }
}
