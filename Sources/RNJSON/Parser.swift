//
//  Parser.swift
//  
//
//  Created by Rob Napier on 2/28/21.
//

import Foundation

public class JSONParser {

    public func parse(data: Data) throws -> JSONValue {
        var tokens = try JSONTokenizer().allTokens(from: data)[...]
        let value = try parseValue(for: &tokens)
        guard tokens.isEmpty else { throw JSONError.unexpectedToken(at: tokens.first!.location, expected: [], found: tokens.first!) }
        return value
    }

    func parseValue<Tokens>(for tokens: inout Tokens) throws -> JSONValue where Tokens: Collection, Tokens.Element == JSONToken, Tokens.SubSequence == Tokens {
        let token = try tokens.requireToken()

        switch token {
        case is JSONTokenArrayOpen:    return try parseArray(for: &tokens)
        case is JSONTokenObjectOpen:   return try parseObject(for: &tokens)
        case is JSONTokenLiteralTrue:  return JSONBool(true)
        case is JSONTokenLiteralFalse: return JSONBool(false)
        case is JSONTokenLiteralNull:  return JSONNull()
        case let t as JSONTokenString: return try JSONString(t)
        case let t as JSONTokenNumber: return try JSONNumber(t)
        default:                       throw JSONError.unexpectedToken(at: token.location, expected: [JSONTokenArrayOpen.self, JSONTokenObjectOpen.self, JSONTokenLiteralTrue.self, JSONTokenLiteralFalse.self, JSONTokenLiteralNull.self, JSONTokenString.self, JSONTokenNumber.self], found: token)
        }
    }

    func parseArray<Tokens>(for tokens: inout Tokens) throws -> JSONArray where Tokens: Collection, Tokens.Element == JSONToken, Tokens.SubSequence == Tokens {
        var elements = JSONArray()

        // Check the first token. It may be an empty list
        do {
            elements.append(try parseValue(for: &tokens))
        } catch let JSONError.unexpectedToken(at: _, expected: _, found: found) where found is JSONTokenArrayClose {
            return elements
        }

        // Check the rest of the tokens
        while true {
            let token = try tokens.requireToken()
            switch token {
            case is JSONTokenArrayClose: return elements
            case is JSONTokenListSeparator: elements.append(try parseValue(for: &tokens))
            default: throw JSONError.unexpectedToken(at: token.location, expected: [JSONTokenArrayClose.self, JSONTokenListSeparator.self], found: token)
            }
        }
    }

    func parseObject<Tokens>(for tokens: inout Tokens) throws -> JSONObject where Tokens: Collection, Tokens.Element == JSONToken, Tokens.SubSequence == Tokens {
        var object = JSONObject()

        var token = try tokens.requireToken()
        if token is JSONTokenObjectClose { return object }

        while true {
            guard let stringToken = token as? JSONTokenString
            else { throw JSONError.unexpectedToken(at: token.location, expected: [JSONTokenString.self], found: token) }

            let key = try JSONString(stringToken)

            let separator = try tokens.requireToken()
            guard separator is JSONTokenKeyValueSeparator else { throw JSONError.unexpectedToken(at: separator.location, expected: [JSONTokenKeyValueSeparator.self], found: separator) }

            object.add(value: try parseValue(for: &tokens), for: key.string)

            token = try tokens.requireToken()

            switch token {
            case is JSONTokenObjectClose: return object
            case is JSONTokenListSeparator: token = try tokens.requireToken()
            default: throw JSONError.unexpectedToken(at: token.location, expected: [JSONTokenObjectClose.self, JSONTokenListSeparator.self], found: token)
            }
        }
    }
}


private extension Collection where Element == JSONToken, SubSequence == Self {
    mutating func removeWhitespace() {
        while let byte = self.first, byte.isIgnored {
            self.removeFirst()
        }
    }

    mutating func requireToken() throws -> JSONToken {
        removeWhitespace()
        return try popFirst() ?? { throw JSONError.dataTruncated }()
    }
}
