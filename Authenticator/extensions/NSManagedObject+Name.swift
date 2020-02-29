//
//  NSManagedObject+Name.swift
//  Authenticator
//
//  Created by skytoup on 2020/2/29.
//  Copyright © 2020 test. All rights reserved.
//

import CoreData

extension NSManagedObject {
    static var name: String {
        entity().name ?? ""
    }
}
