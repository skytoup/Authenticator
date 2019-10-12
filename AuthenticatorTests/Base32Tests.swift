//
//  GoogleAuthCodeTests.swift
//  GoogleAuthCodeTests
//
//  Created by skytoup on 2019/10/4.
//  Copyright © 2019 test. All rights reserved.
//

import Authenticator
import XCTest

class Base32Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecode() {
        // test success
        let str = "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP"
        let data = str.data(using: .utf8)!
        let decodeResult = Base32.decodeChar(data: data)

        XCTAssertEqual(decodeResult?.map { $0 }, [108, 102, 84, 85, 98, 68, 102, 71, 56, 74, 81, 51, 110, 98, 53, 110, 77, 81, 101, 79])

        // test failure
        XCTAssertNil("N1TFIVLCIRTEOOCKKEZW4YRVNZGVCZKP".base32Decode()) // 字符错误
    }
    
    func testPerformanceDecode() {
        measure {
            [
                "NRTFIVLCIRTEOOCKKEZW4YRVNZGVCZKP",
                "2345",
                "NLTFIVLCIRTEOOCKKEZW4YRVNZGVCZK1"
            ].forEach {
                let _ = $0.base32Decode()
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
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
