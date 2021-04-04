//
//  Writer.swift
//  
//
//  Created by Rob Napier on 3/28/21.
//

import Foundation

public class JSONWriter {
    public struct Options : OptionSet {
        public var rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let prettyPrinted = Options(rawValue: 1 << 0)

        /* Sorts dictionary keys for output using [NSLocale systemLocale]. Keys are compared using NSNumericSearch. The specific sorting method used is subject to change.
         */
        public static var sortedKeys = Options(rawValue: 1 << 1)
        public static var withoutEscapingSlashes = Options(rawValue: 1 << 3)
    }

    public init(options: Options = []) { self.options = options }

    public let options: Options

    public func encode(_ value: JSONValue) throws -> String {
        try encode(value, depth: 0)
    }

    private func encode(_ value: JSONValue, depth: Int) throws -> String {
        switch value {
        case let string as JSONString: return "\"\(string.string)\""
        case let number as JSONNumber: return number.digitString
        case let bool as JSONBool: return bool.value ? "true" : "false"
        case let object as JSONObject: return try encode(object: object, depth: depth)
        case let array as JSONArray: return try encode(array: array, depth: depth)
        case is JSONNull: return "null"
        default: throw JSONError.unknownValue(value)
        }
    }

    private func encode(object: JSONObject, depth: Int) throws -> String {
        var afterBrace = ""
        var outsideIndent = ""
        var insideIndent = ""
        var aroundColon = ""
        var afterComma = ""

        if options.contains(.prettyPrinted) {
            afterBrace = "\n"
            outsideIndent = String(repeating: " ", count: 2 * depth)
            insideIndent = String(repeating: " ", count: 2 * (depth + 1))
            aroundColon = " "
            afterComma = "\n"
        }

        let keys = options.contains(.sortedKeys) ? object.keys.sorted() : object.keys

        let keyValues = try keys.map { key in
            try "\(insideIndent)\"\(key)\"\(aroundColon):\(aroundColon)\(encode(object[key]!))" }
        let body = keyValues.joined(separator: ",\(afterComma)")
        return "\(outsideIndent){\(afterBrace)\(body)\(afterComma)\(outsideIndent)}"
    }

    // FIXME: Doesn't pretty-print
    private func encode(array: JSONArray, depth: Int) throws -> String {
        let values = try array.map { (value) in try encode(value) }
        let body = values.joined(separator: ",")
        return "[\(body)]"
    }
}
