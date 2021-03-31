import XCTest
import RNJSON

final class TokenizerTests: XCTestCase {

    func testString() throws {
        let json = Data("""
        "testString"
        """.utf8)

        let tokenizer = JSONTokenizer()

        let tokens = try tokenizer.allTokens(from: json)

        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(tokens[0] is JSONTokenString)
        XCTAssertEqual(tokens[0].length, json.count)
        XCTAssertEqual(tokens[0].data, Data("\"testString\"".utf8))
        XCTAssertEqual(tokens[0].isIgnored, false)
        XCTAssertEqual(tokens[0].location, 0)
        XCTAssertEqual(tokens[0].possiblyTruncated, false)
        XCTAssertEqual((tokens[0] as! JSONTokenString).contents, "testString")
    }
}

// Tests cases from json.org
final class JSONOrgTokenizerTests: XCTestCase {
    func testComplexJSON() throws {
        let url = Bundle.module.url(forResource: "json.org/pass1.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = JSONTokenizer()
        let tokens = try tokenizer.allTokens(from: json)

        XCTAssertEqual(tokens.count, 343)
    }

    func testDeepJSON() throws {
        let url = Bundle.module.url(forResource: "json.org/pass2.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = JSONTokenizer()
        let tokens = try tokenizer.allTokens(from: json)

        XCTAssertEqual(tokens.count, 39)
    }

    func testBareString() throws {
        let url = Bundle.module.url(forResource: "json.org/fail1.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = JSONTokenizer()

        let tokens = try tokenizer.allTokens(from: json)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(tokens[0] is JSONTokenString)
        XCTAssertEqual(json[0..<tokens[0].length], json)
    }

    func testUnterminatedArray() throws {
        let url = Bundle.module.url(forResource: "json.org/fail2.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = JSONTokenizer()
        let tokens = try tokenizer.allTokens(from: json)

        XCTAssertEqual(tokens.count, 2)
        XCTAssertTrue(tokens[0] is JSONTokenArrayOpen)
        XCTAssertTrue(tokens[1] is JSONTokenString)
    }

    func testUnquotedKey() throws {
        let url = Bundle.module.url(forResource: "json.org/fail3.json", withExtension: nil)!
        let json = try Data(contentsOf: url)
        let tokenizer = JSONTokenizer()
        XCTAssertThrowsError(try tokenizer.allTokens(from: json))
    }
}
