//
//  Tokenizer.swift
//  
//
//  Created by Rob Napier on 1/31/21.
//

import Foundation

// Tokenizer splits up Data into semantic components.
// The resulting Tokens can be used to reconstruct the original JSON, including whitespace.
// Tokenizer does the bare minimum required to tokenize. It does not validate that the JSON if valid. For
// example, it does not parse strings; it just looks for a double-quote followed by a non-escaped
// double-quote. This allows parsers to deal with many kinds of technically invalid JSON.

public struct RNJSONTokenizer {
    public enum Error: Swift.Error {
        case unexpectedToken
    }

    public enum Token<Input: DataProtocol>: Equatable {
        case arrayOpen      // [
        case arrayClose     // ]
        case objectOpen     // {
        case objectClose    // }

        case keyValueSeparator  // :
        case listSeparator      // ,

        case literalTrue
        case literalFalse
        case literalNull

        case string(Input.SubSequence)

        case number(Input.SubSequence)

        case whitespace(Input.SubSequence)

        public static func == <Input: DataProtocol>(lhs: Token<Input>, rhs: Token<Input>) -> Bool {
            switch (lhs, rhs) {
            case (.arrayOpen, .arrayOpen),
                 (.arrayClose, .arrayClose),
                 (.objectOpen, .objectOpen),
                 (.objectClose, .objectClose),
                 (.keyValueSeparator, .keyValueSeparator),
                 (.listSeparator, .listSeparator),
                 (.literalTrue, .literalTrue),
                 (.literalFalse, .literalFalse),
                 (.literalNull, .literalNull): return true

            case let (.string(lhs), .string(rhs)),
                 let (.number(lhs), .number(rhs)),
                 let (.whitespace(lhs), .whitespace(rhs)): return lhs.elementsEqual(rhs)

            default:
                return false
            }
        }
    }

    public struct TokenizeResult<Input: DataProtocol> {
        var token: Token<Input>
        var endIndex: Input.Index
    }

    private let trueData = Data("true".utf8)
    private let falseData = Data("false".utf8)
    private let nullData = Data("null".utf8)
    private let whitespaceBytes: [UInt8] = [0x09, 0x0a, 0x0d, 0x20]

    // Extracts first token, if complete. Returns nil if incomplete token is found. Throws for invalid token.
    public func parseFirstToken<Input: DataProtocol>(from data: Input) throws -> TokenizeResult<Input>? {
        guard let byte = data.first else {
            return nil
        }

        switch byte {
        case 0x5b: // [
            return TokenizeResult(token: .arrayOpen, endIndex: data.index(after: data.startIndex))

        case 0x7b:  // {
            return TokenizeResult(token: .objectOpen, endIndex: data.index(after: data.startIndex))

        case 0x5d: // ]
            return TokenizeResult(token: .arrayClose, endIndex: data.index(after: data.startIndex))

        case 0x7d: // ]
            return TokenizeResult(token: .objectClose, endIndex: data.index(after: data.startIndex))

        case 0x3a: // :
            return TokenizeResult(token: .keyValueSeparator, endIndex: data.index(after: data.startIndex))

        case 0x2c: // ,
            return TokenizeResult(token: .listSeparator, endIndex: data.index(after: data.startIndex))

        case 0x74: // t(rue)
            return try extract(.literalTrue, byFinding: trueData, from: data)

        case 0x66: // f(alse)
            return try extract(.literalFalse, byFinding: falseData, from: data)

        case 0x6E: // n(ull)
            return try extract(.literalNull, byFinding: nullData, from: data)

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
    private func extract<Input: DataProtocol>(_ token: Token<Input>, byFinding needle: Data, from data: Input) throws -> TokenizeResult<Input>? {

        // Check that the starting data matches needle
        guard data.starts(with: needle.prefix(data.count)) else {  // true
            throw Error.unexpectedToken
        }

        // Check that the complete needle is found
        guard data.count >= needle.count else {
            return nil
        }

        return TokenizeResult(token: token, endIndex: data.index(data.startIndex, offsetBy: needle.count))
    }

    // Extracts a complete string. If the string is incomplete, return nil. Does not validate string
    private func extractString<Input: DataProtocol>(from data: Input) -> TokenizeResult<Input>? {
        let startStringIndex = data.index(after: data.startIndex) // Drop leading "

        var index = startStringIndex
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
                let stringData = data[startStringIndex..<index]
                let totalStringLength = stringData.count + 2 // Include both "
                return TokenizeResult(token: .string(stringData), endIndex: data.index(data.startIndex, offsetBy: totalStringLength))

            default:
                index = data.index(after: index)
            }
        }

        // Couldn't find end of string
        return nil
    }

    private func extractNumber<Input: DataProtocol>(from data: Input) -> TokenizeResult<Input>? {
        fatalError()
    }

    private func extractWhitespace<Input: DataProtocol>(from data: Input) -> TokenizeResult<Input> {
        let whitespace = data.prefix { whitespaceBytes.contains($0) }
        return TokenizeResult(token: .whitespace(whitespace), endIndex: data.index(data.startIndex, offsetBy: whitespace.count))
    }
}
