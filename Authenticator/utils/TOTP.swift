//
//  TOTP.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/4.
//  Copyright © 2019 test. All rights reserved.
//

import Foundation
import CommonCrypto


/// 非标准TOTP算法, 省略很多参数, 只针对于Google Authoricator使用的部分
/// 主要参考:
///     - https://github.com/google/google-authenticator-libpam/blob/master/src/google-authenticator.c
///     - https://github.com/google/google-authenticator/wiki/Key-Uri-Format
public class TOTP {
    public typealias Params = (issuer: String, secretKey: String, remark: String)
    /// 解析的错误
    public enum ParseError: Error {
        case URL
        case secretKey
        case type
    }
    
    /// 缓存base32解码
    private static let base32Cache = { () -> NSCache<NSString, NSData> in
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 256
        cache.totalCostLimit = 256
        return cache
    }()
    
    
    /// 获取code
    /// - Parameter secretKey: 秘钥
    /// - Parameter tm: 时间点, 默认当前时间戳/30
    public static func genCode(secretKey: String, tm: Int = Int(Date().timeIntervalSince1970) / 30) -> Int? {
        guard let _key = base32Decode(str: secretKey) else { return nil }
        let key = _key.map { $0 }
        let data = time2Bytes(tm).map { $0 }
        
        // 数据进行hmac sha1 hash
        let hmacSha1Result = UnsafeMutablePointer<CChar>.allocate(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, data, data.count, hmacSha1Result)
        
        // 数据取最后一位的后8 bit作为偏移
        let hashData = Data(bytesNoCopy: hmacSha1Result, count: Int(CC_SHA1_DIGEST_LENGTH), deallocator: .none)
        let offset = Int(hashData.last ?? 0) & 0x0F
        // 取偏移和其后4 byte, 转为一个Int32, 再取后6位
        let num = hashData.subdata(in: offset..<offset+4).reduce(0) {
            ($0 << 8) | Int($1)
        } & Int(Int32.max) % 1000000
        hmacSha1Result.deallocate()
        
        return num
    }
    
    /// 构建totp链接
    /// - Parameter params: totp参数
    public static func genURL(_ params: Params) -> String {
        let label = params.remark.count == 0 ? "" : "\(params.issuer):\(params.remark)"
        return "otpauth://totp/\(label)?secret=\(params.secretKey)&issuer=\(params.issuer)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
    }
    
    /// 解析totp链接参数
    /// - Parameter urlStr: totp链接
    public static func parseURL(_ urlStr: String) throws -> Params {
        guard let urlComponent = URLComponents(string: urlStr), let queryItems = urlComponent.queryItems else {
            throw ParseError.URL
        }
        
        guard urlComponent.host == "totp" else {
            throw ParseError.type
        }
        
        let queryItemsDict = queryItems.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value ?? ""
        }
        guard let secretKey = queryItemsDict["secret"], secretKey.count != 0 else {
            throw ParseError.secretKey
        }
        
        let issuer = queryItemsDict["issuer"]?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        
        let ds = urlComponent.path.dropFirst()
        let splitDS = ds.split(separator: ":")
        let remark = (splitDS.count > 1 ? String(splitDS[1]) : String(splitDS[0])).trimmingCharacters(in: CharacterSet.whitespaces)
        
        return (issuer, secretKey, remark)
    }
    
    /// 时间点转bytes
    /// - Parameter tm: 时间点
    private static func time2Bytes(_ tm: Int) -> Data {
        return (0..<8).reversed().reduce((Data(repeating: 0, count: 8), tm)) {
            var d = $0.0
            d[$1] = UInt8($0.1 & 0xFF)
            return (d, $0.1 >> 8)
        }.0
    }
    
    /// 带缓存的base32解码
    /// - Parameter str: 需要解码的字符
    private static func base32Decode(str: String) -> Data? {
        if let b32 = base32Cache.object(forKey: str as NSString) as Data? {
            return b32
        }
        guard let b32 = str.base32Decode() else { return nil }
        base32Cache.setObject(b32 as NSData, forKey: str as NSString)
        return b32
    }
}
