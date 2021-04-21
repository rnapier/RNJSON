//
//  File.swift
//  
//
//  Created by Rob Napier on 4/6/21.
//

import XCTest
import RNJSON


final class JSONTests: XCTestCase {
    static var ditto: Data!

    override class func setUp() {
        let dittoURL = Bundle.module.url(forResource: "ditto", withExtension: "json")!
        ditto = try! Data(contentsOf: dittoURL)
    }

    func testNestedObject() throws {

    }
}
