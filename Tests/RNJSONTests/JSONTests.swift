import XCTest
@testable import RNJSON

struct Customer: Decodable, Equatable {
   let personal: Personal
   let source: String
}

struct Personal: Decodable, Equatable {
    let name: String
    let customer_id: String
    let misc: RNJSON
}

extension JSONEncoder {
    func stringEncode<T>(_ value: T) throws -> String where T : Encodable {
        // JSONEncoder promises to always return UTF-8
        String(data: try self.encode(value), encoding: .utf8)!
    }
}

extension JSONDecoder {
    func stringDecode<T>(_ type: T.Type, from string: String) throws -> T where T : Decodable {
        try JSONDecoder().decode(T.self, from: Data(string.utf8))
    }
}

final class RNJSONTests: XCTestCase {
    func testStringEncode() throws {
        let value = RNJSON("test")
        let result = try JSONEncoder().stringEncode(value)
        let expected = "\"test\""

        XCTAssertEqual(result, expected)
    }

    func testStringDecode() throws {
        let json = "\"test\""
        let result = try JSONDecoder().stringDecode(RNJSON.self, from: json)
        let expectedValue = "test"
        let expectedJSON = RNJSON(expectedValue)

        XCTAssertEqual(result, expectedJSON)
        XCTAssertEqual(try result.stringValue(), expectedValue)
    }

    func testIntEncode() throws {
        let value = RNJSON.number("1")
        let result = try JSONEncoder().stringEncode(value)
        let expected = "1"

        XCTAssertEqual(result, expected)
    }

    func testIntDecode() throws {
        let json = "1"
        let result = try JSONDecoder().stringDecode(RNJSON.self, from: json)
        let expectedValue = 1

        XCTAssertEqual(result, RNJSON(expectedValue))
        XCTAssertEqual(try result.intValue(), expectedValue)
    }

    func testDoubleEncode() throws {
        let value = RNJSON(1.1)
        let result = try JSONEncoder().stringEncode(value)
        let expected = "1.1"

        XCTAssertEqual(result, expected)
    }

    func testDoubleDecode() throws {
        let json = "1.1"
        let result = try JSONDecoder().stringDecode(RNJSON.self, from:json)
        let expectedValue = 1.1

        XCTAssertEqual(result, RNJSON(expectedValue))
        XCTAssertEqual(try result.doubleValue(), expectedValue)
    }

    func testUInt32Encode() throws {
        let value = RNJSON(1 as UInt32)
        let result = try JSONEncoder().stringEncode(value)
        let expected = "1"

        XCTAssertEqual(result, expected)
    }

    func testUInt32Decode() throws {
        let json = "1"
        let result = try JSONDecoder().stringDecode(RNJSON.self, from:json)
        let expectedValue = 1 as UInt32

        XCTAssertEqual(result, RNJSON(expectedValue))
        XCTAssertEqual(try result.numberValue().uint32Value, expectedValue)
    }

    func testBoolEncode() throws {
        let value = RNJSON(true)
        let result = try JSONEncoder().stringEncode(value)
        let expected = "true"

        XCTAssertEqual(result, expected)
    }

    func testBoolDecode() throws {
        let json = "true"
        let result = try JSONDecoder().stringDecode(RNJSON.self, from:json)
        let expectedValue = true

        XCTAssertEqual(result, RNJSON(expectedValue))
        XCTAssertEqual(try result.boolValue(), expectedValue)
    }

    func testObjectEncode() throws {
        let value = RNJSON(["name": "Bob", "age": 43])
        let result = try JSONEncoder().stringEncode(value)
        let expected = "{\"age\":43,\"name\":\"Bob\"}"

        XCTAssertEqual(result, expected)
    }

    func testObjectDecode() throws {
        let json = "{\"name\":\"Bob\",\"age\":43}"
        let result = try JSONDecoder().stringDecode(RNJSON.self, from:json)
        let expectedValue = ["name": "Bob", "age": 43] as JSONObject

        XCTAssertEqual(result, RNJSON(expectedValue))
        XCTAssertEqual(try result.objectValue(), expectedValue)
    }

    func testArrayEncode() throws {
        let value = RNJSON([1,2,3])
        let result = try JSONEncoder().stringEncode(value)
        let expected = "[1,2,3]"

        XCTAssertEqual(result, expected)
    }

    func testArrayDecode() throws {
        let json = "[1,2,3]"
        let result = try JSONDecoder().stringDecode(RNJSON.self, from:json)
        let expectedValue = [1,2,3] as [RNJSON]

        XCTAssertEqual(result, RNJSON(expectedValue))
        XCTAssertEqual(try result.arrayValue(), expectedValue)
    }

    func testNullEncode() throws {
        let value = RNJSON(NSNull())
        let result = try JSONEncoder().stringEncode(value)
        let expected = "null"

        XCTAssertEqual(result, expected)
    }

    func testNullDecode() throws {
        let json = "null"
        let result = try JSONDecoder().stringDecode(RNJSON.self, from:json)
        let expectedValue = RNJSON(NSNull())

        XCTAssertEqual(result, expectedValue)
        XCTAssert(expectedValue.isNull)
    }

//    func testNilEncode() throws {
//        let value = JSON(nil)
//        let result = try JSONEncoder().stringEncode(value)
//        let expected = "null"
//
//        XCTAssertEqual(result, expected)
//    }
//
//    func testNilDecode() throws {
//        let json = "null"
//        let result = try JSONDecoder().stringDecode(JSON.self, from:json)
//        let expectedValue = JSON(nil)
//
//        XCTAssertEqual(result, expectedValue)
//        XCTAssert(expectedValue.isNull)
//    }

    func testNestedDecode() throws {
        let json = Data("""
        {
            "personal": {
                "name": "John Doe",
                "customer_id": "1234",
                "misc": {
                    "active": "true",
                    "addons": {
                        "country": "USA",
                        "state": "Michigan"
                    }
                }
            },
            "source": "main"
        }
        """.utf8)

        let misc: [String: Any] = [
            "active": "true",
            "addons": [
                "country": "USA",
                "state": "Michigan"
            ]
        ]

        let expected = Customer(personal: Personal(name: "John Doe",
                                                   customer_id: "1234", misc: try RNJSON(withAny: misc)), source: "main")

        let parsed = try JSONDecoder().decode(Customer.self, from: json)
        XCTAssertEqual(parsed, expected)
    }

    static var allTests = [
        ("testSimple", testNestedDecode),
    ]
}
