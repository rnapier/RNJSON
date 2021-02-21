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
        RNUnkeyedDecodingContainer(decoder: self, codingPath: codingPath, count: nil, isAtEnd: false, currentIndex: 0)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer { self }
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

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        implement()
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        implement()
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        implement()
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        implement()
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        implement()
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        implement()
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        implement()
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        implement()
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        implement()
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        implement()
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        implement()
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        implement()
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        implement()
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
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
    var decoder: _RNJSONDecoder

    var codingPath: [CodingKey]

    var count: Int?

    var isAtEnd: Bool

    var currentIndex: Int

    mutating func decodeNil() throws -> Bool {
        implement()
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        implement()
    }

    mutating func decode(_ type: String.Type) throws -> String {
        implement()
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        implement()
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        implement()
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        implement()
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        implement()
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        implement()
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        implement()
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        implement()
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        implement()
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        implement()
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        implement()
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        implement()
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        implement()
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try decoder.decode(T.self)
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
