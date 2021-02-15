//
//  Tokenizer.swift
//  
//
//  Created by Rob Napier on 1/31/21.
//

import Foundation

public protocol RNJSONToken {
    var length: Int { get }
}

// Default length
public extension RNJSONToken {
    var length: Int { 1 }
}

public protocol RNJSONLiteralToken: RNJSONToken {
    var value: Data { get }
}

public extension RNJSONLiteralToken {
    var length: Int { value.count }
}

public struct RNJSONTokenArrayOpen: RNJSONToken {}
public struct RNJSONTokenArrayClose: RNJSONToken {}

public struct RNJSONTokenObjectOpen: RNJSONToken {}
public struct RNJSONTokenObjectClose: RNJSONToken {}

public struct RNJSONTokenKeyValueSeparator: RNJSONToken {}
public struct RNJSONTokenListSeparator: RNJSONToken {}

public struct RNJSONTokenLiteralTrue: RNJSONLiteralToken { public var value: Data { Data("true".utf8) } }
public struct RNJSONTokenLiteralFalse: RNJSONLiteralToken { public var value: Data { Data("false".utf8) } }
public struct RNJSONTokenLiteralNull: RNJSONLiteralToken { public var value: Data { Data("null".utf8) } }

public struct RNJSONTokenString: RNJSONToken { public var length: Int }
public struct RNJSONTokenNumber: RNJSONToken { public var length: Int }
public struct RNJSONTokenWhitespace: RNJSONToken { public var length: Int }

// Tokenizer splits up Data into semantic components.
// The resulting Tokens can be used to reconstruct the original JSON, including whitespace.
// Tokenizer does the bare minimum required to tokenize. It does not validate that the JSON if valid. For
// example, it does not parse strings; it just looks for a double-quote followed by a non-escaped
// double-quote. This allows parsers to deal with many kinds of technically invalid JSON.

public struct RNJSONTokenizer {
    public enum Error: Swift.Error {
        case unexpectedToken
    }

    private let whitespaceBytes: [UInt8] = [0x09, 0x0a, 0x0d, 0x20]
    private let numberBytes: [UInt8] = [0x2b,   // +
                                        0x2d,   // -
                                        0x2e,   // .
                                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, // 0-9
                                        0x45,   // E
                                        0x65    // e
    ]

    // Extracts first token, if complete. Returns nil if incomplete token is found. Throws for invalid token.
    public func parseFirstToken<Input: DataProtocol>(from data: Input) throws -> RNJSONToken? {
        guard let byte = data.first else {
            return nil
        }

        switch byte {
        case 0x5b: // [
            return RNJSONTokenArrayOpen()

        case 0x7b: // {
            return RNJSONTokenObjectOpen()

        case 0x5d: // ]
            return RNJSONTokenArrayClose()

        case 0x7d: // }
            return RNJSONTokenObjectClose()

        case 0x3a: // :
            return RNJSONTokenKeyValueSeparator()

        case 0x2c: // ,
            return RNJSONTokenListSeparator()

        case 0x74: // t(rue)
            return try extract(RNJSONTokenLiteralTrue(), from: data)

        case 0x66: // f(alse)
            return try extract(RNJSONTokenLiteralFalse(), from: data)

        case 0x6E: // n(ull)
            return try extract(RNJSONTokenLiteralNull(), from: data)

        case 0x22: // "
            return extractString(from: data)

        case 0x2d, 0x30...0x49: // -, 0-9
            return extractNumber(from: data)

        case 0x09, 0x0a, 0x0d, 0x20: // consume whitespace
            return extractWhitespace(from: data)

        default:
            throw Error.unexpectedToken
        }
    }

    // data must begin with a prefix of needle, or this throws. data may be incomplete, so a partial prefix returns nil.
    private func extract<Input: DataProtocol>(_ token: RNJSONLiteralToken, from data: Input) throws -> RNJSONToken? {
        let needle = token.value

        // Check that the starting data matches needle
        guard data.starts(with: needle.prefix(data.count)) else {
            throw Error.unexpectedToken
        }

        // Check that the complete needle is found
        guard data.count >= needle.count else {
            return nil
        }

        return token
    }

    // Extracts a complete string (including quotation marks). If the string is incomplete, return nil.
    // Does not validate string. Any characters between unescaped double-quotes are returned.
    private func extractString<Input: DataProtocol>(from data: Input) -> RNJSONToken? {
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
                let totalStringLength = data.distance(from: data.startIndex, to: index) + 1
                return RNJSONTokenString(length: totalStringLength)

            default:
                index = data.index(after: index)
            }
        }

        // Couldn't find end of string
        return nil
    }

    // Extracts a complete number. If the number may be incomplete (is not followed by a non-number), return nil.
    // Does not validate the number. Any sequence of "number-like" characters is accepted
    private func extractNumber<Input: DataProtocol>(from data: Input) -> RNJSONToken? {
        let numbers = data.prefix { numberBytes.contains($0) }
        if numbers.count == data.count { return nil }
        return RNJSONTokenNumber(length: numbers.count)
    }

    private func extractWhitespace<Input: DataProtocol>(from data: Input) -> RNJSONToken {
        let whitespace = data.prefix { whitespaceBytes.contains($0) }
        return RNJSONTokenWhitespace(length: whitespace.count)
    }
}
