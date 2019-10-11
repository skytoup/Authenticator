//
//  RealmDB.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/2.
//  Copyright © 2019 test. All rights reserved.
//

import RealmSwift

class RealmDB {
    static let share = RealmDB()
    
    private var thread2DB = Dictionary<Thread, Realm>()
    private var spLock = os_unfair_lock()
    
    var db: Realm? {
        os_unfair_lock_lock(&self.spLock)
        defer {
            os_unfair_lock_unlock(&self.spLock)
        }

        if let r = self.thread2DB[Thread.current] {
            return r
        } else {
            let r: Realm?
            do {
                r = try Realm()
            } catch {
                if let fp = Realm.Configuration.defaultConfiguration.fileURL {
                    try? FileManager.default.removeItem(at: fp)
                }
                r = try? Realm()
            }
            self.thread2DB[Thread.current] = r
            return r
        }
    }
    
    fileprivate init() {
        var data : CFTypeRef?
        var status = SecItemCopyMatching([
            kSecClass as NSString : kSecClassGenericPassword as NSString,
            kSecAttrService as NSString : Bundle.main.bundleIdentifier ?? "realm",
            kSecAttrAccount as NSString : "realm",
            kSecReturnData as NSString : kCFBooleanTrue!
        ] as NSDictionary, &data)
        
        var key: Data?
        if status != errSecItemNotFound {
            guard status == errSecSuccess, let data = data as? Data else {
                print("realm encrypt key read failure: \(status)")
                return
            }
            key = data
        }
        
        if key == nil {
            key = Data(count: 64)
            key?.withUnsafeMutableBytes {
                guard let p = $0.bindMemory(to: UInt8.self).baseAddress else {
                    return
                }
                _ = SecRandomCopyBytes(kSecRandomDefault, 64, p)
            }
            status = SecItemAdd([
                kSecClass as NSString : kSecClassGenericPassword as NSString,
                kSecAttrService as NSString : Bundle.main.bundleIdentifier ?? "realm",
                kSecAttrAccount as NSString : "realm",
                kSecValueData as NSString : key!
            ] as NSDictionary, nil)
            guard status == errSecSuccess else {
                print("realm encrypt key save failure: \(status)")
                return
            }
        }
        Realm.Configuration.defaultConfiguration.encryptionKey = key
    }
}
