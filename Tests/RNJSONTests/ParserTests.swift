import XCTest
@testable import RNJSON

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
    func testStringDecode() throws {
        let json = "\"test\""
        let result = try JSONParser().parse(data: Data(json.utf8))
        let expectedValue = "test"

        XCTAssert(result is JSONString)
        XCTAssertEqual(try result.stringValue(), expectedValue)
    }

    func testIntDecode() throws {
        let json = "1"
        let result = try JSONParser().parse(data: Data(json.utf8))
        let expectedValue = 1

        XCTAssert(result is JSONNumber)
        XCTAssertEqual(try result.intValue(), expectedValue)
    }

    func testDoubleDecode() throws {
        let json = "1.1"
        let result = try JSONParser().parse(data: Data(json.utf8))
        let expectedValue = 1.1

        XCTAssert(result is JSONNumber)
        XCTAssertEqual(try result.doubleValue(), expectedValue)
    }

    func testBoolDecode() throws {
        let json = "true"
        let result = try JSONParser().parse(data: Data(json.utf8))
        let expectedValue = true

        XCTAssert(result is JSONBool)
        XCTAssertEqual(try result.boolValue(), expectedValue)
    }

    func testObjectDecode() throws {
        let json = "{\"name\":\"Bob\",\"age\":43}"
        let result = try JSONParser().parse(data: Data(json.utf8))

        XCTAssert(result is JSONObject)
        XCTAssertEqual(try result["name"]?.stringValue(), "Bob")
        XCTAssertEqual(try result["age"]?.intValue(), 43)
    }

    func testArrayDecode() throws {
        let json = "[1,2,3]"
        let result = try JSONParser().parse(data: Data(json.utf8))

        XCTAssert(result is JSONArray)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(try result[0]?.intValue(), 1)
        XCTAssertEqual(try result[1]?.intValue(), 2)
        XCTAssertEqual(try result[2]?.intValue(), 3)
    }

    func testNullDecode() throws {
        let json = "null"
        let result = try JSONParser().parse(data: Data(json.utf8))

        XCTAssert(result is JSONNull)
        XCTAssert(result.isNull)
    }

//
//    func testNestedDecode() throws {
//        let json = Data("""
//        {
//            "personal": {
//                "name": "John Doe",
//                "customer_id": "1234",
//                "misc": {
//                    "active": "true",
//                    "addons": {
//                        "country": "USA",
//                        "state": "Michigan"
//                    }
//                }
//            },
//            "source": "main"
//        }
//        """.utf8)
//
//        let misc: [String: Any] = [
//            "active": "true",
//            "addons": [
//                "country": "USA",
//                "state": "Michigan"
//            ]
//        ]
//
//        let expected = Customer(personal: Personal(name: "John Doe",
//                                                   customer_id: "1234", misc: try RNJSON(withAny: misc)), source: "main")
//
//        let parsed = try JSONDecoder().decode(Customer.self, from: json)
//        XCTAssertEqual(parsed, expected)
//    }
//
//    static var allTests = [
//        ("testSimple", testNestedDecode),
//    ]
}
