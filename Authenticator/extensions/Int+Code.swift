//
//  Int+Code.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/5.
//  Copyright © 2019 test. All rights reserved.
//

import Foundation

extension Int {
    var codeString: String {
        var cs = String(format: "%06d", self)
        cs.insert(" ", at: cs.index(cs.startIndex, offsetBy: 3))
        return cs
    }
}
