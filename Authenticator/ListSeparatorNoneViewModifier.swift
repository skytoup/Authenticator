//
//  ListSeparatorNoneViewModifier.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/21.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI

struct ListSeparatorNoneViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                UITableView.appearance().separatorStyle = .none
            }
            .onDisappear {
                UITableView.appearance().separatorStyle = .singleLine
            }
    }
}
