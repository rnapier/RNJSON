import Foundation

@dynamicMemberLookup
public enum JSON: Hashable {
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case object([Key: JSON])
    case array([JSON])
    case null
}

// MARK: - Errors
public extension JSON {
    enum Error: Swift.Error {
        case typeMismatch
    }
}

// MARK: - CodingKey
public extension JSON {
    struct Key: CodingKey, Hashable, CustomStringConvertible {
        public var description: String { stringValue }

        public let stringValue: String
        public init(_ string: String) { self.stringValue = string }
        public init?(stringValue: String) { self.init(stringValue) }
        public var intValue: Int? { nil }
        public init?(intValue: Int) { nil }
    }
}

// MARK: - String
public extension JSON {
    var isString: Bool {
        if case .string = self { return true } else { return false }
    }

    func stringValue() throws -> String {
        guard case .string(let value) = self else { throw Error.typeMismatch }
        return value
    }
}

// MARK: - Number
public extension JSON {
    var isNumber: Bool {
        if case .number = self { return true } else { return false }
    }

    func numberValue() throws -> NSNumber {
        guard case .number(let value) = self else { throw Error.typeMismatch }
        return value
    }

    func doubleValue() throws -> Double {
        try numberValue().doubleValue
    }

    func intValue() throws -> Int {
        try numberValue().intValue
    }

    func decimalValue() throws -> Decimal {
        try numberValue().decimalValue
    }
}

// MARK: - Bool
public extension JSON {
    var isBool: Bool {
        if case .bool = self { return true } else { return false }
    }

    func boolValue() throws -> Bool {
        guard case .bool(let value) = self else { throw Error.typeMismatch }
        return value
    }
}

// MARK: - Object
public extension JSON {
    var isObject: Bool {
        if case .object = self { return true } else { return false }
    }

    func objectValue() throws -> [String: JSON] {
        guard case .object(let value) = self else { throw Error.typeMismatch }
        return Dictionary(uniqueKeysWithValues:
                            value.map { (key, value) in (key.stringValue, value) })
    }

    subscript(key: String) -> JSON? {
        guard let jsonKey = Key(stringValue: key),
              case .object(let object) = self,
              let value = object[jsonKey]
        else { return nil }
        return value
    }
}

// MARK: - Array
public extension JSON {
    var isArray: Bool {
        if case .array = self { return true } else { return false }
    }

    func arrayValue() throws -> [JSON] {
        guard case .array(let value) = self else { throw Error.typeMismatch }
        return value
    }

    subscript(index: Int) -> JSON {
        switch self {
        case .array(let array): return array[index]
        default: preconditionFailure("Type mismatch")
        }
    }
}

// MARK: - Null
public extension JSON {
    var isNull: Bool {
        if case .null = self { return true } else { return false }
    }
}

// MARK: - Dynamic Member Lookup
public extension JSON {
    subscript(dynamicMember member: String) -> JSON {
        return self[member] ?? .null
    }
}

// MARK: - Decodable
extension JSON: Decodable {
    public init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) { self = .string(string) }

        else if let number = try? decoder.singleValueContainer().decode(Decimal.self) { self = .number(number as NSNumber) }

        else if let bool = try? decoder.singleValueContainer().decode(Bool.self) { self = .bool(bool) }

        else if let object = try? decoder.container(keyedBy: Key.self) {
            var result: [Key: JSON] = [:]
            for key in object.allKeys {
                result[key] = (try? object.decode(JSON.self, forKey: key)) ?? .null
            }
            self = .object(result)
        }

        else if var array = try? decoder.unkeyedContainer() {
            var result: [JSON] = []
            for _ in 0..<(array.count ?? 0) {
                result.append(try array.decode(JSON.self))
            }
            self = .array(result)
        }

        else if let isNull = try? decoder.singleValueContainer().decodeNil(), isNull { self = .null }

        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [],
                                                                       debugDescription: "Unknown JSON type")) }
    }
}

// MARK: - Encodable
extension JSON: Encodable {
    public func encode(to encoder: Encoder) throws {
        switch self {

        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)

        case .number(let number):
            var container = encoder.singleValueContainer()
            try container.encode(number.decimalValue)

        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)

        case .object(let object):
            var container = encoder.container(keyedBy: Key.self)
            for (key, value) in object {
                try container.encode(value, forKey: key)
            }

        case .array(let array):
            var container = encoder.unkeyedContainer()
            for value in array {
                try container.encode(value)
            }

        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

// MARK: - CustomStringConvertible
extension JSON: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let string): return "\"\(string)\""

        case .number(let number): return "\(number)"

        case .bool(let bool): return "\(bool)"

        case .object(let object):
            let keyValues = object
                .map { (key, value) in "\"\(key)\": \(value)" }
                .joined(separator: ",")
            return "{\(keyValues)}"

        case .array(let array): return "\(array)"

        case .null: return "null"
        }
    }
}

// MARK: - Any
public extension JSON {
    init(_ value: Any) throws {
        if let string = value as? String { self = .string(string) }

        else if let number = value as? NSNumber { self = .number(number) }

        else if let bool = value as? Bool { self = .bool(bool) }

        else if let object = value as? [String: Any] {
            var result: [Key: JSON] = [:]
            for (key, subvalue) in object {
                result[Key(key)] = try JSON(subvalue)
            }
            self = .object(result)
        }

        else if let array = value as? [Any] {
            self = .array(try array.map(JSON.init))
        }

        else if value is NSNull { self = .null }

        else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [],
                                                                          debugDescription: "Cannot encode value"))
        }
    }

    func anyValue() -> Any {
        (try? stringValue()) ??
            (try? numberValue()) ??
            (try? boolValue()) ??
            (try? objectValue()) ??
            (try? arrayValue()) ??
            NSNull()
    }

    func dictionaryValue() throws -> [String: Any] {
        guard let value = anyValue() as? [String: Any] else { throw Error.typeMismatch }
        return value
    }
}
