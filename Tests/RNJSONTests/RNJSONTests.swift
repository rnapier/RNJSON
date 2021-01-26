import XCTest
@testable import RNJSON

struct Customer: Decodable, Equatable {
   let personal: Personal
   let source: String
}

struct Personal: Decodable, Equatable {
    let name: String
    let customer_id: String
    let misc: JSON
}

final class RNJSONTests: XCTestCase {
    func testSimple() throws {
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
                                                   customer_id: "1234", misc: try JSON(misc)), source: "main")

        let parsed = try JSONDecoder().decode(Customer.self, from: json)
        XCTAssertEqual(parsed, expected)

    }

    static var allTests = [
        ("testSimple", testSimple),
    ]
}
