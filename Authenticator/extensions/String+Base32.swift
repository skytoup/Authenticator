//
//  String+Base32.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/4.
//  Copyright © 2019 test. All rights reserved.
//

import Foundation

extension String {
    public func base32Decode(using encode: String.Encoding = .utf8) -> Data? {
        guard let ds = data(using: encode) else { return nil }
        return Base32.decodeChar(data: ds)
    }
}
