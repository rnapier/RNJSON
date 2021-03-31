//
//  Writer.swift
//  
//
//  Created by Rob Napier on 3/28/21.
//

import Foundation

public class JSONWriter {
    public init() {}

    func encode<T>(_ value: T, codingPath: [CodingKey] = []) throws -> Data where T : JSONValue {
//        let leadingWhitespace = value.metadata[.leadingWhitespace] as? Data ?? Data()
//        let trailingWhitespace = value.metadata[.trailingWhitespace] as? Data ?? Data()

        let content: Data

        switch value {
        case let string as JSONString: content = encode(string: string.string)
        case let number as JSONNumber: content = Data(number.digitString.utf8)
        case let bool as JSONBool: content = encode(string: bool.value ? "true": "false")
        case let object as JSONObject: content = try encode(object: object)
        case let array as JSONArray: content = try encode(array: array)
        case is JSONNull: content = encode(string: "null")
        default: throw JSONError.unknownValue(value)
        }
        return content
//        return leadingWhitespace + content + trailingWhitespace
    }

    private func encode(string: String) -> Data {
        Data("\"\(string)\"".utf8)
    }

    private func encode(object: JSONObject) throws -> Data {

        var content = Data()

        for (key, value) in object.keyValues {
            content += try encode(key)
        }

        fatalError()

    }

    private func encode(array: JSONArray) throws -> Data {
        fatalError()
    }
}
