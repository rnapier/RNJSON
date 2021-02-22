//
//  File.swift
//  
//
//  Created by Rob Napier on 2/20/21.
//

import Foundation

private func implement(file: StaticString = #file, line: UInt = #line) -> Never { fatalError(file: file, line: line) }

class RNJSONDecoder {
    init() {}

    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        try T.init(from: _RNJSONDecoder(data: data))
    }
}

class _RNJSONDecoder: Decoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    var data: Data

    init(data: Data) {
        self.data = data
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(RNKeyedDecodingContainer(decoder: self, codingPath: [], allKeys: []))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try RNUnkeyedDecodingContainer(decoder: self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer { self }

    func consume(_ string: String) -> Bool {
        let prefix = string.utf8
        guard data.starts(with: prefix) else {
            return false
        }
        data.removeFirst(prefix.count)
        return true
    }
}

struct RNKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var decoder: _RNJSONDecoder
    var codingPath: [CodingKey]

    var allKeys: [Key]

    func contains(_ key: Key) -> Bool {
        implement()
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        implement()
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        implement()
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        implement()
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        implement()
    }

    func superDecoder() throws -> Decoder {
        implement()
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        implement()
    }
}

struct RNUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    mutating func decodeNil() throws -> Bool {
        implement()
    }

    var decoder: _RNJSONDecoder
    var codingPath: [CodingKey] = []
    var count: Int?
    var isAtEnd: Bool = false
    var currentIndex: Int = 0

    init(decoder: _RNJSONDecoder) throws {
        self.decoder = decoder
        if !decoder.consume("[") {
            throw DecodingError.typeMismatch([Any].self, .init(codingPath: codingPath,
                                                               debugDescription: "IMPLEMENT"))
        }
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let value = try decoder.decode(T.self)
        if decoder.consume("]") {
            isAtEnd = true
        } else if !decoder.consume(",") {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Missing , or ]")
        }
        currentIndex += 1
        return value

    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        implement()
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        implement()
    }

    mutating func superDecoder() throws -> Decoder {
        implement()
    }
}

extension _RNJSONDecoder: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        data.starts(with: "null".utf8)
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        if data.starts(with: "true".utf8) { return true }
        if data.starts(with: "false".utf8) { return false }
        throw DecodingError.typeMismatch(String.self,
                                         .init(codingPath: codingPath,
                                               debugDescription: "Expected to decode Bool."))
    }

    // FIXME: Fully verify legal string
    func decode(_ type: String.Type) throws -> String {
        guard data.first == 0x22 else {
            throw DecodingError.typeMismatch(String.self,
                                             .init(codingPath: codingPath,
                                                   debugDescription: "Expected to decode String."))
        }

        var index = data.index(after: data.startIndex) // Drop leading "

        LOOP: while index < data.endIndex {
            switch data[index] {
            case 0x5c: // \
                // Don't worry about what the next character is. At this point, we're not validating
                // the string, just looking for an unescaped double-quote.
                if !data.formIndex(&index, offsetBy: 2, limitedBy: data.endIndex) {
                    // Couldn't advance by 2, so data ends in a \
                    break LOOP
                }

            case 0x22: // "
                guard let string = String(data: data[data.startIndex + 1..<index], encoding: .utf8)
                else {
                    throw DecodingError.dataCorrupted(.init(codingPath: codingPath,
                                                            debugDescription: "The given data was not valid JSON.",
                                                            underlyingError: NSError(domain: NSCocoaErrorDomain,
                                                                                     code: NSPropertyListReadCorruptError,
                                                                                     userInfo: [NSDebugDescriptionErrorKey: "Unable to convert data to string around character \(data.startIndex)."])))
                }
                return string

            default:
                index = data.index(after: index)
            }
        }

        // Couldn't find end of string
        implement()
    }

    func decode(_ type: Double.Type) throws -> Double {
        let numberBytes: [UInt8] = [0x2b,   // +
                                    0x2d,   // -
                                    0x2e,   // .
                                    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, // 0-9
                                    0x45,   // E
                                    0x65    // e
        ]
        let numbers = data.prefix { numberBytes.contains($0) }
        guard let string = String(data: numbers, encoding: .utf8),
              let value = Double(string) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath,
                                                    debugDescription: "The given data was not valid JSON.",
                                                    underlyingError: NSError(domain: NSCocoaErrorDomain,
                                                                             code: NSPropertyListReadCorruptError,
                                                                             userInfo: [NSDebugDescriptionErrorKey: "Unable to convert data to number around character \(data.startIndex)."])))
        }
        data.removeFirst(numbers.count)
        return value
    }

    func decode(_ type: Float.Type) throws -> Float {
        try Float(decode(Double.self))
    }

    // FIXME: Don't go through Double; this loses values
    func decode(_ type: Int.Type) throws -> Int {
        try Int(decode(Double.self))
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try Int8(decode(Int.self))
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try Int16(decode(Int.self))
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try Int32(decode(Int.self))
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try Int64(decode(Int.self))
    }

    // FIXME: Don't go through Double; this loses values
    func decode(_ type: UInt.Type) throws -> UInt {
        try UInt(decode(Double.self))
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try UInt8(decode(UInt.self))
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try UInt16(decode(UInt.self))
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try UInt32(decode(UInt.self))
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try UInt64(decode(UInt.self))
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try T.init(from: self)
    }
}
