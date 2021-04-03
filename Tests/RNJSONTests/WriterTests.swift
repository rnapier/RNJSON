//
//  WriterTests.swift
//  
//
//  Created by Rob Napier on 3/28/21.
//

import XCTest
import RNJSON

final class WriterTests: XCTestCase {

    func testString() throws {
        let writer = JSONWriter()

        let json = try writer.encode(JSONString("TestData"))

        XCTAssertEqual(json, Data("\"TestData\"".utf8))
    }

}
