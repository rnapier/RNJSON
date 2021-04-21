import XCTest
import RNJSON

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

        XCTAssertEqual(try result.stringValue(), expectedValue)
    }

    func testIntDecode() throws {
        let json = "1"
        let result = try JSONParser().parse(data: Data(json.utf8))
        let expectedValue = 1

        XCTAssertEqual(try result.intValue(), expectedValue)
    }

    func testDoubleDecode() throws {
        let json = "1.1"
        let result = try JSONParser().parse(data: Data(json.utf8))
        let expectedValue = 1.1

        XCTAssertEqual(try result.doubleValue(), expectedValue)
    }

    func testBoolDecode() throws {
        let json = "true"
        let result = try JSONParser().parse(data: Data(json.utf8))
        let expectedValue = true

        XCTAssertEqual(try result.boolValue(), expectedValue)
    }

    func testObjectDecode() throws {
        let json = "{\"name\":\"Bob\",\"age\":43}"
        let result = try JSONParser().parse(data: Data(json.utf8))

        XCTAssertEqual(try result["name"]?.stringValue(), "Bob")
        XCTAssertEqual(try result["age"]?.intValue(), 43)
    }

    func testArrayDecode() throws {
        let json = "[1,2,3]"
        let result = try JSONParser().parse(data: Data(json.utf8))

        XCTAssertEqual(try result.count(), 3)
        XCTAssertEqual(try result[0].intValue(), 1)
        XCTAssertEqual(try result[1].intValue(), 2)
        XCTAssertEqual(try result[2].intValue(), 3)
    }

    func testNullDecode() throws {
        let json = "null"
        let result = try JSONParser().parse(data: Data(json.utf8))

        XCTAssert(result.isNull)
    }

    func testDitto() throws {
        let dittoURL = Bundle.module.url(forResource: "ditto", withExtension: "json")!
        let json = try Data(contentsOf: dittoURL)
        let ditto = try JSONParser().parse(data: json)

        let w1 = try ditto.keyValues().last?.value.intValue()
        XCTAssertEqual(w1, 40)

        let w2 = try ditto["weight"]?.intValue()
        XCTAssertEqual(w2, 40)

        let w3 = try ditto.weight.intValue()
        XCTAssertEqual(w3, 40)

        let w4 = try ditto.dictionaryValue()["weight"]?.intValue()
        XCTAssertEqual(w4, 40)
    }
}
