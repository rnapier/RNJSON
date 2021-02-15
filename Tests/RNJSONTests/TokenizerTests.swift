import XCTest
@testable import RNJSON

final class TokenizerTests: XCTestCase {

    func testString() throws {
        let json = Data("""
        "testString"
        """.utf8)

        let tokenizer = RNJSONTokenizer()

        let result = try tokenizer.parseFirstToken(from: json)

        XCTAssertEqual(result?.token, RNJSONTokenizer.Token<Data>.string(Data("testString".utf8)))
        XCTAssertEqual(result?.endIndex, json.endIndex)
    }

}

// Tests cases from json.org
final class JSONOrgTokenizerTests: XCTestCase {
    func testBareString() throws {
        let url = Bundle.module.url(forResource: "json.org/fail1.json", withExtension: nil)!
        let json = try Data(contentsOf: url)

        let tokenizer = RNJSONTokenizer()

        var tokens: [RNJSONTokenizer.TokenizeResult<Data>] = []
        var index = json.startIndex
        while index < json.endIndex {
            let result = try tokenizer.parseFirstToken(from: json[index...])!
            tokens.append(result)
            index = result.endIndex
        }

        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0].token, RNJSONTokenizer.Token<Data>.string(Data("A JSON payload should be an object or array, not a string.".utf8)))
        XCTAssertEqual(tokens[0].endIndex, json.endIndex)
    }
}
