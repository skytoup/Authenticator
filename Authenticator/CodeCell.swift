//
//  CodeCell.swift
//  Watch Extension
//
//  Created by skytoup on 2020/2/19.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct CodeCell: View {
    // MARK: - view
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(data.issuer).font(.headline)
                codeText
                if !data.remark.isEmpty {
                    Text(data.remark).font(.subheadline)
                }
            }
            .padding()
            Spacer()
        }
    }

    var data: TOTP.Params
    var code: String
    var isRefreshSoon: Bool
    
    var codeText: some View {
        let text = Text(code).foregroundColor(isRefreshSoon ? .red : .blue)
        #if os(iOS)
        return text.font(.system(size: 38))
        #elseif os(watchOS)
        return text.font(.title)
        #else
        return text
        #endif
    }
    
}

struct CodeCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CodeCell(data: ("name", "code", "remark"), code: "--- ---", isRefreshSoon: false)
        }
    }
}
