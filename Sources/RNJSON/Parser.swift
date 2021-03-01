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
        guard tokens.isEmpty else { throw JSONError.unexpectedToken }
        return value
    }

    func parseValue<Tokens>(for tokens: inout Tokens) throws -> JSONValue where Tokens: Collection, Tokens.Element == JSONToken, Tokens.SubSequence == Tokens {
        tokens.removeWhitespace()
        guard let token = tokens.popFirst() else { throw JSONError.dataTruncated }

        switch token {
        case is JSONTokenArrayOpen:    return try parseArray(for: &tokens)
        case is JSONTokenObjectOpen:   return try parseArray(for: &tokens)
        case is JSONTokenLiteralTrue:  return JSONBool(true)
        case is JSONTokenLiteralFalse: return JSONBool(false)
        case is JSONTokenLiteralNull:  return JSONNull()
        case is JSONTokenString:       return try JSONString(data: token.data)
        case is JSONTokenNumber:       return try JSONNumber(data: token.data)
        default:                       throw JSONError.unexpectedToken
        }
    }

    func parseArray<Tokens>(for tokens: inout Tokens) throws -> JSONArray where Tokens: Collection, Tokens.Element == JSONToken, Tokens.SubSequence == Tokens {
        var elements = JSONArray()

        var token = try tokens.requireToken()
        if token is JSONTokenArrayClose { return elements }

        while true {
            elements.append(try parseValue(for: &tokens))
            token = try tokens.requireToken()
            switch token {
            case is JSONTokenArrayClose: break
            case is JSONTokenListSeparator: token = try tokens.requireToken()
            default: throw JSONError.unexpectedToken
            }
        }
        return elements
    }

    func parseObject<Tokens>(for tokens: inout Tokens) throws -> JSONObject where Tokens: Collection, Tokens.Element == JSONToken, Tokens.SubSequence == Tokens {
        var object = JSONObject()

        var token = try tokens.requireToken()
        if token is JSONTokenObjectClose { return object }

        while true {
            guard let stringToken = token as? JSONTokenString,
                  let key = stringToken.utf8String
            else { throw JSONError.unexpectedToken }

            guard try tokens.requireToken() is JSONTokenKeyValueSeparator else { throw JSONError.unexpectedToken }

            object.add(value: try parseValue(for: &tokens), for: key)

            token = try tokens.requireToken()

            switch token {
            case is JSONTokenObjectClose: break
            case is JSONTokenListSeparator: token = try tokens.requireToken()
            default: throw JSONError.unexpectedToken
            }
        }
        return object
    }
}


private extension Collection where Element == JSONToken, SubSequence == Self {
    mutating func removeWhitespace() {
        self = self.drop(while: \.isIgnored)
    }

    mutating func requireToken() throws -> JSONToken {
        removeWhitespace()
        return try popFirst() ?? { throw JSONError.dataTruncated }()
    }
}
