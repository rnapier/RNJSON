import XCTest
@testable import RNJSON

struct Customer: Decodable {
   let personal: Personal
   let source: String
}

struct Personal: Decodable {
    let name: String
    let customer_id: String
    let misc: JSON
}

final class RNJSONTests: XCTestCase {
    func testExample() throws {
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

        let parsed = try JSONDecoder().decode(Customer.self, from: json)
        print(parsed.personal.misc)

    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
