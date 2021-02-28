//
//  Parser.swift
//  
//
//  Created by Rob Napier on 2/28/21.
//

import Foundation

public class JSONParser {

    public func parse(data: Data) throws -> JSONValue {
        return try parseValue(for: try JSONTokenizer().allTokens(from: data))
    }

    func parseValue<Tokens>(for tokens: Tokens) throws -> JSONValue where Tokens: Collection, Tokens.Element == JSONToken {

        let (token, rest) = try tokens.nextToken()

        switch token {
        case is JSONTokenArrayOpen:    return try parseArray(for: rest)
        case is JSONTokenObjectOpen:   return try parseArray(for: rest)
        case is JSONTokenLiteralTrue:  return JSONBool(true)
        case is JSONTokenLiteralFalse: return JSONBool(false)
        case is JSONTokenLiteralNull:  return JSONNull()
        case is JSONTokenString:       return try JSONString(data: token.data)
        case is JSONTokenNumber:       return try JSONNumber(data: token.data)
        default:                       throw JSONError.unexpectedToken
        }
    }

    func parseArray<Tokens>(for tokens: Tokens) throws -> JSONArray where Tokens: Collection, Tokens.Element == JSONToken {
        var elements: [JSONValue] = []

        repeat {
            let (token, _) = try tokens.nextToken()
            if token is JSONTokenArrayClose { return JSONArray(elements) }
            else { elements.append(try parseValue(for: tokens)) }
        } while true
    }

    func parseObject<Tokens>(for tokens: Tokens) throws -> JSONObject where Tokens: Collection, Tokens.Element == JSONToken {
        fatalError()
    }

}

private extension Collection where Element == JSONToken {
    func dropWhitespace() -> SubSequence {
        drop(while: { $0 is JSONTokenWhitespace })
    }

    func nextToken() throws -> (JSONToken, SubSequence) {
        let tokens = self.dropWhitespace()
        guard let token = tokens.first else { throw JSONError.dataTruncated }
        return (token, tokens)
    }
}
