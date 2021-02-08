import XCTest
@testable import RNJSON

final class TokenizerTests: XCTestCase {

    func testString() throws {
        let json = Data("""
        "testString"
        """.utf8)

        let tokenizer = RNJSONTokenizer()

        let result = try tokenizer.parseFirstToken(from: json)

        XCTAssertEqual(result.token, RNJSONTokenizer.Token<Data>.string(Data("testString".utf8)))
        XCTAssertEqual(result.endIndex, json.endIndex)
    }

}
