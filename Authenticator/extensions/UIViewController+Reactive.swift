//
//  UIViewController+Reactive.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/1.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit
import ReactiveSwift

extension Reactive where Base : UIViewController {
    var isModalInPresentation: BindingTarget<Bool> {
        return makeBindingTarget { $0.isModalInPresentation = $1}
    }
}
