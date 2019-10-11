//
//  reactive+UITextField.swift
//  Authenticator
//
//  Created by skytoup on 2019/9/29.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit
import ReactiveSwift

protocol IntRangeContainerProtocol {
    func contains(_ element: Int) -> Bool
}

extension Range : IntRangeContainerProtocol where Bound == Int {}
extension ClosedRange : IntRangeContainerProtocol where Bound == Int {}

extension Signal where Value == String {
    // 字符长度是否在指定范围内
    func countInRange(range: IntRangeContainerProtocol) -> Signal<Bool, Error> {
        return self.map {
            range.contains($0.count)
        }
    }
}
