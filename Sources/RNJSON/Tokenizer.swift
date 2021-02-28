//
//  Tokenizer.swift
//
//
//  Created by Rob Napier on 1/31/21.
//

import Foundation

public protocol JSONToken {
    var data: Data { get }
    var possiblyTruncated: Bool { get }
}

public extension JSONToken {
    var length: Int { data.count }
    var possiblyTruncated: Bool { false }
}

public struct JSONTokenArrayOpen: JSONToken { public let data = Data("[".utf8) }
public struct JSONTokenArrayClose: JSONToken { public let data = Data("]".utf8) }

public struct JSONTokenObjectOpen: JSONToken { public let data = Data("{".utf8) }
public struct JSONTokenObjectClose: JSONToken { public let data = Data("}".utf8) }

public struct JSONTokenKeyValueSeparator: JSONToken { public let data = Data(":".utf8)}
public struct JSONTokenListSeparator: JSONToken { public let data = Data(",".utf8)}

public struct JSONTokenLiteralTrue: JSONToken { public let data = Data("true".utf8) }
public struct JSONTokenLiteralFalse: JSONToken { public let data = Data("false".utf8) }
public struct JSONTokenLiteralNull: JSONToken { public let data = Data("null".utf8) }

public struct JSONTokenString: JSONToken { public var data: Data }

public struct JSONTokenNumber: JSONToken {
    public var data: Data
    public var possiblyTruncated: Bool
}

public struct JSONTokenWhitespace: JSONToken {
    public var data: Data
    public var possiblyTruncated: Bool
}

// Tokenizer splits up Data into semantic components.
// The resulting Tokens can be used to reconstruct the original JSON, including whitespace.
// Tokenizer does the bare minimum required to tokenize. It does not verify that the JSON if valid. For
// example, it does not parse strings; it just looks for a double-quote followed by a non-escaped
// double-quote. This allows parsers to deal with many kinds of technically invalid JSON.

public struct JSONTokenizer {
    public enum Error: Swift.Error {
        case unexpectedToken
        case dataTruncated
    }

    private let whitespaceBytes: [UInt8] = [0x09, 0x0a, 0x0d, 0x20]
    private let numberBytes: [UInt8] = [0x2b,   // +
                                        0x2d,   // -
                                        0x2e,   // .
                                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, // 0-9
                                        0x45,   // E
                                        0x65    // e
    ]

    public func parseAll(data: Data) throws -> [JSONToken] {
        var json = data
        var tokens: [JSONToken] = []
        while !json.isEmpty {
            let result = try parseFirstToken(from: json)
            tokens.append(result)
            json.removeFirst(result.length)
        }
        return tokens
    }

    // Extracts first token. Returns nil if incomplete token is found. Throws for invalid token. Note that
    // it is possible for a number to be incomplete if data is not complete. It is up to the caller to check
    // for that situation.
    public func parseFirstToken(from data: Data) throws -> JSONToken {
        guard let byte = data.first else {
            throw Error.dataTruncated
        }

        switch byte {
        case 0x5b: // [
            return JSONTokenArrayOpen()

        case 0x7b: // {
            return JSONTokenObjectOpen()

        case 0x5d: // ]
            return JSONTokenArrayClose()

        case 0x7d: // }
            return JSONTokenObjectClose()

        case 0x3a: // :
            return JSONTokenKeyValueSeparator()

        case 0x2c: // ,
            return JSONTokenListSeparator()

        case 0x74: // t(rue)
            return try extract(JSONTokenLiteralTrue(), from: data)

        case 0x66: // f(alse)
            return try extract(JSONTokenLiteralFalse(), from: data)

        case 0x6E: // n(ull)
            return try extract(JSONTokenLiteralNull(), from: data)

        case 0x22: // "
            return try extractString(from: data)

        case 0x2d, 0x30...0x49: // -, 0-9
            return extractNumber(from: data)

        case 0x09, 0x0a, 0x0d, 0x20: // consume whitespace
            return extractWhitespace(from: data)

        default:
            throw Error.unexpectedToken
        }
    }

    // data must begin with a prefix of needle, or this throws.
    private func extract(_ token: JSONToken, from data: Data) throws -> JSONToken {
        let needle = token.data

        // Check that the starting data matches needle
        guard data.starts(with: needle.prefix(data.count)) else {
            throw Error.unexpectedToken
        }

        // Check that the complete needle is found
        guard data.count >= needle.count else {
            throw Error.dataTruncated
        }

        return token
    }

    // Extracts a complete string (including quotation marks). If the string is incomplete, throw .dataTruncated.
    // Does not validate string. Any characters between unescaped double-quotes are returned.
    private func extractString(from data: Data) throws -> JSONToken {
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
                return JSONTokenString(data: data.prefix(through: index))

            default:
                index = data.index(after: index)
            }
        }

        // Couldn't find end of string
        throw Error.dataTruncated
    }

    // Extracts a number. Does not validate the number. Any sequence of "number-like" characters is accepted.
    // Note that it is possible that this number is truncated; the caller must check for that situation.
    private func extractNumber(from data: Data) -> JSONToken {
        let number = data.prefix { numberBytes.contains($0) }
        return JSONTokenNumber(data: number, possiblyTruncated: number.count == data.count)
    }

    private func extractWhitespace(from data: Data) -> JSONToken {
        let whitespace = data.prefix { whitespaceBytes.contains($0) }
        return JSONTokenWhitespace(data: whitespace, possiblyTruncated: whitespace.count == data.count)
    }
}
