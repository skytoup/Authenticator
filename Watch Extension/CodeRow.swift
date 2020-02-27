//
//  CodeRow.swift
//  Watch Extension
//
//  Created by skytoup on 2020/2/19.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct CodeCell: View {
    var data: TOTP.Params
    var code: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(data.issuer)
            Text(code)
                .foregroundColor(.blue)
                .font(.title)
            Text(data.remark)
        }.padding()
    }
}

struct ACodeRow_Previews: PreviewProvider {
    static var previews: some View {
        CodeCell(data: ("name", "code", "remark"), code: "--- ---")
    }
}
