//
//  ImgSaver.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/26.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit

class ImgSaver: NSObject {
    var complationHandler: ((Result<Void, Error>) -> Void)?
    
    func saveToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(img), nil)
    }

    @objc fileprivate func img(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let err = error {
            complationHandler?(.failure(err))
        } else {
            complationHandler?(.success(()))
        }
    }
}
