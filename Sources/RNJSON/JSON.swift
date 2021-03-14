import Foundation

// MARK: - Errors
enum JSONError: Swift.Error {
    case unexpectedByte(at: Int, found: [UInt8])
    case unexpectedToken(at: Int, expected: [JSONToken.Type], found: JSONToken)
    case dataTruncated
    case typeMismatch
    case dataCorrupted
    case missingValue
}

public protocol JSONValue {
    func stringValue() throws -> String

    func doubleValue() throws -> Double

    func decimalValue() throws -> Decimal
    func intValue() throws -> Int

    func boolValue() throws -> Bool

    func get(_ key: String) throws -> JSONValue
    func getAll(_ key: String) throws -> [JSONValue]
    subscript(_ key: String) -> JSONValue? { get }

    var count: Int { get }
    func get(_ index: Int) throws -> JSONValue
    subscript(_ index: Int) -> JSONValue? { get }

    func isNull() -> Bool
}

// Default implementations
public extension JSONValue {
    func stringValue() throws -> String { throw JSONError.typeMismatch }

    func doubleValue() throws -> Double { throw JSONError.typeMismatch }

    func decimalValue() throws -> Decimal { throw JSONError.typeMismatch }
    func intValue() throws -> Int { throw JSONError.typeMismatch }

    func boolValue() throws -> Bool { throw JSONError.typeMismatch }

    func get(_ key: String) throws -> JSONValue { throw JSONError.typeMismatch }
    func getAll(_ key: String) throws -> [JSONValue] { throw JSONError.typeMismatch }
    subscript(_ key: String) -> JSONValue? { nil }

    var count: Int { 1 }
    func get(_ index: Int) throws -> JSONValue { throw JSONError.typeMismatch }
    subscript(_ index: Int) -> JSONValue? { nil }

    func isNull() -> Bool { false }
}

public struct JSONString: JSONValue {
    public var string: String
    public init(_ string: String) { self.string = string }
    public func stringValue() throws -> String { string }

    public init(_ token: JSONTokenString) throws {
        // FIXME: Validate
        guard let string = token.contents else { throw JSONError.dataCorrupted }
        self.init(string)
    }
}

public struct JSONNumber: JSONValue {
    public var digitString: String
    public init<Number: FixedWidthInteger>(_ number: Number) { self.digitString = "\(number)" }

    init(_ token: JSONTokenNumber) throws { self.digitString = try String(data: token.data, encoding: .utf8) ?? { throw JSONError.dataCorrupted }() } // FIXME: Validate

    public func doubleValue() throws -> Double { try convert(to: Double.self) }
    public func decimalValue() throws -> Decimal { try Decimal(string: digitString) ?? { throw JSONError.typeMismatch }()}
    public func intValue() throws -> Int { try convert(to: Int.self) }

    private func convert<N: LosslessStringConvertible>(to: N.Type) throws -> N {
        try N.init(digitString) ?? { throw JSONError.typeMismatch }()
    }
}

public struct JSONBool: JSONValue {
    public var value: Bool
    public init(_ value: Bool) { self.value = value }
    public func boolValue() throws -> Bool { value }
}

public struct JSONObject: JSONValue {
    public var keyValues: [(key: String, value: JSONValue)]
    public init() { self.keyValues = [] }
    public mutating func add(value: JSONValue, for key: String) {
        keyValues.append((key: key, value: value))
    }

    public var count: Int { keyValues.count }
    public func get(_ key: String) throws -> JSONValue { try self[key] ?? { throw JSONError.missingValue }() }
    public func getAll(_ key: String) -> [JSONValue] { keyValues.filter({ $0.key == key }).map(\.value) }
    public subscript(_ key: String) -> JSONValue? { keyValues.first(where: { $0.key == key })?.value }
}

public struct JSONArray: JSONValue {
    public var elements: [JSONValue]
    public init(_ elements: [JSONValue] = []) { self.elements = elements }
    public mutating func append(_ element: JSONValue) {
        elements.append(element)
    }
    public var count: Int { elements.count }
    public func get(_ index: Int) throws -> JSONValue { try self[index] ?? { throw JSONError.missingValue }() }
    public subscript(_ index: Int) -> JSONValue? { elements.indices.contains(index) ? elements[index] : nil }
}

public struct JSONNull: JSONValue {
    public func isNull() -> Bool { true }
}


//@dynamicMemberLookup
//public enum RNJSON: Hashable {
//    case string(String)
//    case number(String)
//    case bool(Bool)
//    case object([String: RNJSON])
//    case array([RNJSON])
//    case null
//}
//

//
//// MARK: - StringKey
//private struct StringKey: CodingKey, Hashable, Comparable, CustomStringConvertible, ExpressibleByStringLiteral {
//    public var description: String { stringValue }
//
//    public let stringValue: String
//    public init(_ string: String) { self.stringValue = string }
//    public init?(stringValue: String) { self.init(stringValue) }
//    public var intValue: Int? { nil }
//    public init?(intValue: Int) { nil }
//
//    public static func < (lhs: StringKey, rhs: StringKey) -> Bool { lhs.stringValue < rhs.stringValue }
//
//    public init(stringLiteral value: String) { self.init(value) }
//}
//
//// MARK: - String
//public extension RNJSON {
//    var isString: Bool {
//        if case .string = self { return true } else { return false }
//    }
//
//    func stringValue() throws -> String {
//        guard case .string(let value) = self else { throw Error.typeMismatch }
//        return value
//    }
//
//    init(_ value: String) {
//        self = .string(value)
//    }
//}
//
//extension RNJSON: ExpressibleByStringLiteral {
//    public init(stringLiteral value: String) {
//        self = .string(value)
//    }
//}
//
//// MARK: - Number
//public extension RNJSON {
//    var isNumber: Bool {
//        if case .number = self { return true } else { return false }
//    }
//
//    func numberValue() throws -> NSNumber {
//        guard case .number(let value) = self,
//              let number = Decimal(string: value)
//              else { throw Error.typeMismatch }
//
//        return number as NSNumber
//    }
//
//    func doubleValue() throws -> Double { try numberValue().doubleValue }
//    func intValue() throws -> Int { try numberValue().intValue }
//    func decimalValue() throws -> Decimal { try numberValue().decimalValue }
//
//    init(_ value: NSNumber) { self = .number(value.stringValue) }
//
//    init(_ value: Int8)   { self.init(value as NSNumber) }
//    init(_ value: Double) { self.init(value as NSNumber) }
//    init(_ value: Float)  { self.init(value as NSNumber) }
//    init(_ value: Int32)  { self.init(value as NSNumber) }
//    init(_ value: Int)    { self.init(value as NSNumber) }
//    init(_ value: Int64)  { self.init(value as NSNumber) }
//    init(_ value: Int16)  { self.init(value as NSNumber) }
//    init(_ value: UInt8)  { self.init(value as NSNumber) }
//    init(_ value: UInt32) { self.init(value as NSNumber) }
//    init(_ value: UInt)   { self.init(value as NSNumber) }
//    init(_ value: UInt64) { self.init(value as NSNumber) }
//    init(_ value: UInt16) { self.init(value as NSNumber) }
//}
//
//extension RNJSON: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
//    public init(integerLiteral value: Int) { self.init(value) }
//    public init(floatLiteral value: Double) { self.init(value) }
//}
//
//// MARK: - Bool
//public extension RNJSON {
//    var isBool: Bool {
//        if case .bool = self { return true } else { return false }
//    }
//
//    func boolValue() throws -> Bool {
//        guard case .bool(let value) = self else { throw Error.typeMismatch }
//        return value
//    }
//
//    init(_ value: Bool) {
//        self = .bool(value)
//    }
//}
//
//// MARK: - Object
//public extension RNJSON {
//    var isObject: Bool {
//        if case .object = self { return true } else { return false }
//    }
//
//    func objectValue() throws -> [String: RNJSON] {
//        guard case .object(let value) = self else { throw Error.typeMismatch }
//        return value
//    }
//
//    subscript(key: String) -> RNJSON? {
//        try? objectValue()[key]
//    }
//
//    init(_ value: [String: RNJSON]) {
//        self = .object(value)
//    }
//}
//
//extension RNJSON: ExpressibleByDictionaryLiteral {
//    public init(dictionaryLiteral elements: (String, RNJSON)...) {
//        self.init(Dictionary(uniqueKeysWithValues: elements))
//    }
//}
//
//public typealias JSONObject = [String: RNJSON]
//
//// MARK: - Array
//public extension RNJSON {
//    var isArray: Bool {
//        if case .array = self { return true } else { return false }
//    }
//
//    func arrayValue() throws -> [RNJSON] {
//        guard case .array(let value) = self else { throw Error.typeMismatch }
//        return value
//    }
//
//    subscript(index: Int) -> RNJSON {
//        guard let array = try? arrayValue(),
//              array.indices.contains(index)
//        else { return .null }
//
//        return array[index]
//    }
//
//    init(_ value: [RNJSON]) {
//        self = .array(value)
//    }
//}
//
//extension RNJSON: ExpressibleByArrayLiteral {
//    public init(arrayLiteral elements: RNJSON...) {
//        self.init(elements)
//    }
//}
//
//// MARK: - Null
//public extension RNJSON {
//    var isNull: Bool {
//        if case .null = self { return true } else { return false }
//    }
//
//    init(_ value: NSNull) {
//        self = .null
//    }
//}
//
////extension JSON: ExpressibleByNilLiteral {
////    public init(nilLiteral: Void) {
////        self.init(NSNull())
////    }
////}
//
//// MARK: - Dynamic Member Lookup
//public extension RNJSON {
//    subscript(dynamicMember member: String) -> RNJSON {
//        self[member] ?? .null
//    }
//}
//
//// MARK: - Decodable
//extension RNJSON: Decodable {
//    public init(from decoder: Decoder) throws {
//        if let string = try? decoder.singleValueContainer().decode(String.self) { self = .string(string) }
//
//        else if let number = try? decoder.singleValueContainer().decode(Decimal.self) { self = .number("\(number)") }
//
//        else if let bool = try? decoder.singleValueContainer().decode(Bool.self) { self = .bool(bool) }
//
//        else if let object = try? decoder.container(keyedBy: StringKey.self) {
//            let pairs = try object.allKeys.map(\.stringValue).map { key in
//                (key, try object.decode(RNJSON.self, forKey: StringKey(key)))
//            }
//            self = .object(Dictionary(uniqueKeysWithValues: pairs))
//        }
//
//        else if var array = try? decoder.unkeyedContainer() {
//            var result: [RNJSON] = []
//            while !array.isAtEnd {
//                result.append(try array.decode(RNJSON.self))
//            }
//            self = .array(result)
//        }
//
//        else if let isNull = try? decoder.singleValueContainer().decodeNil(), isNull { self = .null }
//
//        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [],
//                                                                       debugDescription: "Unknown JSON type")) }
//    }
//}
//
//// MARK: - Encodable
//extension RNJSON: Encodable {
//    public func encode(to encoder: Encoder) throws {
//        switch self {
//
//        case .string(let string):
//            var container = encoder.singleValueContainer()
//            try container.encode(string)
//
//        case .number(let number):
//            var container = encoder.singleValueContainer()
//            try container.encode(Decimal(string: number))
//
//        case .bool(let bool):
//            var container = encoder.singleValueContainer()
//            try container.encode(bool)
//
//        case .object(let object):
//            var container = encoder.container(keyedBy: StringKey.self)
//            for key in object.keys.sorted() {
//                try container.encode(object[key], forKey: StringKey(key))
//            }
//
//        case .array(let array):
//            var container = encoder.unkeyedContainer()
//            for value in array {
//                try container.encode(value)
//            }
//
//        case .null:
//            var container = encoder.singleValueContainer()
//            try container.encodeNil()
//        }
//    }
//}
//
//// MARK: - CustomStringConvertible
//extension RNJSON: CustomStringConvertible {
//    public var description: String {
//        switch self {
//        case .string(let string): return "\"\(string)\""
//
//        case .number(let number): return "\(number)"
//
//        case .bool(let bool): return "\(bool)"
//
//        case .object(let object):
//            let keyValues = object
//                .map { (key, value) in "\"\(key)\": \(value)" }
//                .joined(separator: ",")
//            return "{\(keyValues)}"
//
//        case .array(let array): return "\(array)"
//
//        case .null: return "null"
//        }
//    }
//}
//
//// MARK: - Any
//public extension RNJSON {
//    init(withAny value: Any) throws {
//        switch value {
//        case let json as RNJSON: self = json
//        case let string as String: self = RNJSON(string)
//        case let number as NSNumber: self = RNJSON(number)
//        case let bool as Bool: self = RNJSON(bool)
//        case let object as [String: Any]: self = RNJSON(try object.mapValues(RNJSON.init(withAny:)))
//        case let array as [Any]: self = RNJSON(try array.map(RNJSON.init(withAny:)))
//        case is NSNull: self = .null
//        default:
//            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [],
//                                                                          debugDescription: "Cannot encode value"))
//        }
//    }
//
//    func anyDictionary() throws -> [String: Any] {
//        try objectValue().mapValues(RNJSON.anyValue)
//    }
//
//    func anyArray() throws -> [Any] {
//        try arrayValue().map(RNJSON.anyValue)
//    }
//
//    func anyValue() throws -> Any {
//        switch self {
//        case .string(let value): return value
//        case .number(let value): return value
//        case .bool(let value): return value
//        case .object(let object): return object.mapValues(RNJSON.anyValue)
//        case .array(let array): return array.map(RNJSON.anyValue)
//        case .null: return NSNull()
//        }
//    }
//}
