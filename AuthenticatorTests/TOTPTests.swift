//
//  TOTPTests.swift
//  GoogleAuthCodeTests
//
//  Created by skytoup on 2019/10/4.
//  Copyright © 2019 test. All rights reserved.
//

import XCTest
import Authenticator

class TOTPTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGen() {
        XCTAssertEqual(TOTP.genCode(secretKey: "NGVXRWGAWQ3WQC65ZVRTES6LA6N3APAV", tm: 1024), 253980)
        
        XCTAssertNil(TOTP.genCode(secretKey: "N1TFIVLCIRTEOOCKKEZW4YRVNZGVCZKP", tm: 1024)) // 字符错误
    }
    
    func testParseURL() {
         let urls = [
            "otpauth://totp/Google:test%40gmail.com?secret=NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP&issuer=Google",
            "otpauth://totp/Google%20test:%20test@gmail.com?secret=NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP&issuer=Google%20test",
            "otpauth://totp/test@gmail.com?secret=NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP&issuer=Google%20test",
        ]
        let datas = [
            ("Google", "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP", "test@gmail.com"),
            ("Google test", "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP", "test@gmail.com"),
            ("Google test", "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP", "test@gmail.com"),
        ]
        
        let results = urls.map { try? TOTP.parseURL($0) }
        zip(results, datas).forEach {
            XCTAssertNotNil($0)
            XCTAssertEqual($0!.0, $1.0)
            XCTAssertEqual($0!.1, $1.1)
            XCTAssertEqual($0!.2, $1.2)
        }
    }
    
    func testGenURL() {
        let datas = [
            ("Google", "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP", "test@gmail.com"),
            ("Google test", "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP", "test@gmail.com"),
        ]
        let urls = [
            "otpauth://totp/Google:test@gmail.com?secret=NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP&issuer=Google",
            "otpauth://totp/Google%20test:test@gmail.com?secret=NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP&issuer=Google%20test",
        ]
        
        let results = datas.map { TOTP.genURL($0) }
        zip(results, urls).forEach {
            XCTAssertEqual($0, $1)
        }
    }
    
    func testPerformanceGen() {
        self.measure {
            [
                "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP",
                "2345",
                "NLTFIVLCIRTEOOCKKEZW4YRVNZGVCZK1"
            ].forEach {
                let _ = TOTP.genCode(secretKey: $0, tm: 1024)
            }
        }
    }
    
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
