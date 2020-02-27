//
//  ImagePicker.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/26.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import MobileCoreServices

struct ImagePicker: UIViewControllerRepresentable {
    typealias FinishPickingBlock = (_ info: [UIImagePickerController.InfoKey : Any]) -> Void
        
    var finishPicking: FinishPickingBlock? = nil
    
    class Coodrdinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var finishPicking: ((_ info: [UIImagePickerController.InfoKey : Any]) -> Void)?
        
        init(finishPicking: FinishPickingBlock? = nil) {
            self.finishPicking = finishPicking
            
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            finishPicking?(info)
            picker.dismiss(animated: true, completion: nil)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coodrdinator {
        Coodrdinator(finishPicking: finishPicking)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let ipc = UIImagePickerController()
        ipc.delegate = context.coordinator
        ipc.mediaTypes = [kUTTypeImage as String]
        ipc.sourceType = .photoLibrary
        return ipc
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
}
