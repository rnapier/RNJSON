//
//  Writer.swift
//  
//
//  Created by Rob Napier on 3/28/21.
//

import Foundation

public class JSONWriter {
    public init() {}

    public func encode(_ value: JSONValue) throws -> Data {
        let content: Data

        switch value {
        case let string as JSONString: content = encode(string: string.string)
        case let number as JSONNumber: content = Data(number.digitString.utf8)
        case let bool as JSONBool: content = encode(bool: bool.value)
        case let object as JSONObject: content = try encode(object: object)
        case let array as JSONArray: content = try encode(array: array)
        case is JSONNull: content = Data("null".utf8)
        default: throw JSONError.unknownValue(value)
        }
        return content
    }

    private func encode(string: String) -> Data {
        Data("\"\(string)\"".utf8)
    }

    private func encode(bool: Bool) -> Data {
        Data((bool ? "true" : "false").utf8)
    }

    private func encode(object: JSONObject) throws -> Data {
        let keyValues = try object.map { (key, value) in try Data("\"\(key)\":".utf8) + encode(value) }
        let body = Data(keyValues.joined(separator: ",".utf8))
        return Data("{".utf8) + body + Data("}".utf8)
    }

    private func encode(array: JSONArray) throws -> Data {
        let values = try array.map { (value) in try encode(value) }
        let body = Data(values.joined(separator: ",".utf8))
        return Data("[".utf8) + body + Data("]".utf8)
    }
}
