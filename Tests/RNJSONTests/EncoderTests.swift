//
//  File.swift
//  
//
//  Created by Rob Napier on 4/3/21.
//

import XCTest
import RNJSON

final class RNJSONEncoderTests: XCTestCase {
    func testString() throws {
        let value = "testString"

        let json = String(data: try RNJSONEncoder().encode(value), encoding: .utf8)

        let expected = """
        "testString"
        """

        XCTAssertEqual(json, expected)
    }
}
