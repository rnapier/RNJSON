//
//  File.swift
//  
//
//  Created by Rob Napier on 2/20/21.
//

import XCTest
import RNJSON

final class RNJSONDecoderTests: XCTestCase {

    func testStringMismatch() throws {
        let json = Data("""
        123
        """.utf8)

        XCTAssertThrowsError(try RNJSONDecoder().decode(String.self, from: json)) { error in
            XCTAssert(error is DecodingError)
            switch error as! DecodingError {
            case .typeMismatch(let type, let context):
                XCTAssert(type == String.self)
                XCTAssert(context.codingPath.isEmpty)
                XCTAssertEqual(context.debugDescription, "Expected to decode String but found a number instead.")
                XCTAssertNil(context.underlyingError)
            default: XCTFail()
            }
        }
    }

    func testStringCorrupt() throws {
        let json = Data([0x22, 0x80, 0x22]) // Invalid UTF-8 byte inside quotes.
        XCTAssertThrowsError(try RNJSONDecoder().decode(String.self, from: json)) { error in
            XCTAssert(error is DecodingError)
            switch error as! DecodingError {
            case .dataCorrupted(let context):
                XCTAssert(context.codingPath.isEmpty)
                XCTAssertEqual(context.debugDescription, "The given data was not valid JSON.")
                // TODO: Check underlying error to determine where error occurred.
            default: XCTFail()
            }
        }
    }

    func testNil() throws {
        let json = Data("""
        null
        """.utf8)

        let result = try RNJSONDecoder().decode(String?.self, from: json)
        XCTAssertNil(result)
    }

    func testTrue() throws {
        let json = Data("""
        true
        """.utf8)

        let result = try RNJSONDecoder().decode(Bool.self, from: json)
        XCTAssertTrue(result)
    }

    func testFalse() throws {
        let json = Data("""
        false
        """.utf8)

        let result = try RNJSONDecoder().decode(Bool.self, from: json)
        XCTAssertFalse(result)
    }

    func testNotBool() throws {
        let json = Data("""
        "true"
        """.utf8)

        XCTAssertThrowsError(try RNJSONDecoder().decode(Bool.self, from: json)) { error in
            XCTAssert(error is DecodingError)
            switch error as! DecodingError {
            case .typeMismatch(let type, let context):
                XCTAssert(type == Bool.self)
                XCTAssert(context.codingPath.isEmpty)
                XCTAssertEqual(context.debugDescription, "Expected to decode Bool but found a string/data instead.")
                XCTAssertNil(context.underlyingError)
            default: XCTFail()
            }
        }
    }

    func testDouble() throws {
        let json = Data("""
            1.0
            """.utf8)

        let result = try RNJSONDecoder().decode(Double.self, from: json)
        XCTAssertEqual(result, 1.0)
    }

    func testFloat() throws {
        let json = Data("""
            1.0
            """.utf8)

        let result = try RNJSONDecoder().decode(Float.self, from: json)
        XCTAssertEqual(result, 1.0)
    }

    func testInt() throws {
        let json = Data("""
            1
            """.utf8)

        let result = try RNJSONDecoder().decode(Int.self, from: json)
        XCTAssertEqual(result, 1)
    }

    func testArray() throws {
        let json = Data("""
            [1,1]
            """.utf8)

        let result = try RNJSONDecoder().decode([Int].self, from: json)
        XCTAssertEqual(result, [1, 1])
    }

    func testDecimal() throws {
        let json = Data("""
            123
            """.utf8)

        let result = try RNJSONDecoder().decode(Decimal.self, from: json)
        XCTAssertEqual(result, Decimal(123))
    }

    func testSubDecode() throws {
        struct Group: Codable, Equatable {
            var id: String
            var name: String
        }

        let json = Data("""
            {
            "groups": [
              {
                "id": "oruoiru",
                "testProp": "rhorir",
                "name": "* C-Level",
                "description": "C-Level"
              },
              {
                "id": "seese",
                "testProp": "seses",
                "name": "CDLevel",
                "description": "CDLevel"
              }
            ],
            "totalCount": 41
            }
            """.utf8)

        let decoder = RNJSONDecoder()
        let response = try decoder.decode(JSON.self, from: json)
        let groupsArray = response.groups
        let groups = try decoder.decode([Group].self, from: groupsArray)

        let expected = [
            Group(id: "oruoiru", name: "* C-Level"),
            Group(id: "seese", name: "CDLevel")
        ]

        XCTAssertEqual(groups, expected)
    }
}
