//
//  MarkedTextField.swift
//  Authenticator
//
//  Created by skytoup on 2020/5/10.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct MarkedTextField: UIViewRepresentable {
    
    fileprivate let tf = UITextField(frame: .zero)
    @Binding var text: String
    
    init(_ placeholder: String = "", text: Binding<String>) {
        _text = text
        tf.placeholder = placeholder
        tf.text = text.wrappedValue
        tf.borderStyle = .roundedRect
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(mtf: self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        tf.delegate = context.coordinator
        return tf
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let mtf: MarkedTextField
        
        init(mtf: MarkedTextField) {
            self.mtf = mtf
            
            super.init()
            
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: mtf.tf, queue: nil) { [weak self] _ in
                guard let tf = self?.mtf.tf, tf.markedTextRange == nil else {
                    return
                }
                self?.mtf.text = tf.text ?? ""
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
}

