//
//  CodeCell.swift
//  Watch Extension
//
//  Created by skytoup on 2020/2/19.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct CodeCell: View {
    var data: TOTP.Params
    var code: String
    
    var codeText: some View {
        let text = Text(code).foregroundColor(.blue)
        #if os(iOS)
        return text.font(.system(size: 38))
        #elseif os(watchOS)
        return text.font(.title)
        #else
        return text
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(data.issuer)
            codeText
            Text(data.remark)
        }.padding()
    }
}

struct CodeCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CodeCell(data: ("name", "code", "remark"), code: "--- ---")
        }
    }
}
