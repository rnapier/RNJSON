import XCTest
@testable import RNJSON

final class TokenizerTests: XCTestCase {

    func testString() throws {
        let json = Data("""
        "testString"
        """.utf8)

        let tokenizer = JSONTokenizer()

        let result = try tokenizer.firstToken(from: json)

        XCTAssertTrue(result is JSONTokenString)
        XCTAssertEqual(result.length, json.count)
    }

}

// Tests cases from json.org
final class JSONOrgTokenizerTests: XCTestCase {
    func testComplexJSON() throws {
        let url = Bundle.module.url(forResource: "json.org/pass1.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = JSONTokenizer()

        let tokens = try tokenizer.allTokens(from: json)

        XCTAssertEqual(tokens.count, 301)
    }

    func testBareString() throws {
        let url = Bundle.module.url(forResource: "json.org/fail1.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = JSONTokenizer()

        var tokens: [JSONToken] = []
        var index = json.startIndex
        while index < json.endIndex {
            let result = try tokenizer.firstToken(from: json[index...])
            tokens.append(result)
            index = index.advanced(by: result.length)
        }

        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(tokens[0] is JSONTokenString)
        XCTAssertEqual(json[0..<tokens[0].length], json)
    }

    func testUnterminatedArray() throws {
        let url = Bundle.module.url(forResource: "json.org/fail2.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = JSONTokenizer()

        var tokens: [JSONToken] = []
        var index = json.startIndex
        while index < json.endIndex {
            let result = try tokenizer.firstToken(from: json[index...])
            tokens.append(result)
            index = index.advanced(by: result.length)
        }

        XCTAssertEqual(tokens.count, 2)
        XCTAssertTrue(tokens[0] is JSONTokenArrayOpen)
        XCTAssertTrue(tokens[1] is JSONTokenString)
    }
}
