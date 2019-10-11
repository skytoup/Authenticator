//
//  Data+Base32.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/4.
//  Copyright © 2019 test. All rights reserved.
//

import Foundation

extension Data {
    public func base32Decode() -> Data? {
        return Base32.decodeChar(data: self)
    }
}
