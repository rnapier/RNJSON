import Foundation

// MARK: - Errors
public enum JSONError: Swift.Error {
    case unexpectedByte(at: Int, found: [UInt8])
    case unexpectedToken(at: Int, expected: [JSONToken.Type], found: JSONToken)
    case dataTruncated
    case typeMismatch
    case dataCorrupted
    case missingValue
}

public enum JSON {
    public static let formatter = NumberFormatter()

    case string(String)
    case number(digits: String)
    case bool(Bool)
    case object(keyValues: JSONKeyValues)
    case array(JSONArray)
    case null

    public init(_ convertible: LosslessJSONConvertible) { self = convertible.jsonValue() }
    public init(_ convertible: JSONConvertible) throws { self = try convertible.jsonValue() }
}

// String
extension JSON {
    public func stringValue() throws -> String {
        guard case let .string(value) = self else { throw JSONError.typeMismatch }
        return value
    }
}

// Number
extension JSON {
    public func doubleValue() throws -> Double {
        guard case let .number(digits) = self, let value = Double(digits) else { throw JSONError.typeMismatch }
        return value
    }

    public func decimalValue() throws -> Decimal {
        guard case let .number(digits) = self, let value = Decimal(string: digits) else { throw JSONError.typeMismatch }
        return value
    }

    public func intValue() throws -> Int {
        guard case let .number(digits) = self, let value = Int(digits) else { throw JSONError.typeMismatch }
        return value
    }

    func digits() throws -> String {
        guard case let .number(digits) = self else { throw JSONError.typeMismatch }
        return digits
    }
}

// Bool
extension JSON {
    public func boolValue() throws -> Bool {
        guard case let .bool(value) = self else { throw JSONError.typeMismatch }
        return value
    }
}

// Object

public typealias JSONKeyValues = [(key: String, value: JSON)]

extension JSONKeyValues {
    public var keys: [String] { self.map(\.key) }

    public subscript(_ key: String) -> JSON? {
        get { self.first(where: { $0.key == key })?.value }
        set {
            if let value = newValue {
                if let index = self.firstIndex(where: { $0.key == key}) {
                    self[index] = (key: key, value: value)
                } else {
                    self.append((key: key, value: value))
                }
            } else {
                if let index = self.firstIndex(where: { $0.key == key }) {
                    self.remove(at: index)
                }
            }
        }
    }
}

extension JSON {
    public func objectValue() throws -> JSONKeyValues {
        guard case let .object(object) = self else { throw JSONError.typeMismatch }
        return object
    }

    public func dictionaryValue() throws -> [String: JSON] {
        guard case let .object(object) = self else { throw JSONError.typeMismatch }
        return Dictionary(object, uniquingKeysWith: { first, _ in first })
    }

    public func getValue(for key: String) throws -> JSON {
        guard let value = self[key] else { throw JSONError.missingValue }
        return value
    }

    public func getAllValues(for key: String) throws -> [JSON] {
        guard case let .object(object) = self else { throw JSONError.typeMismatch }
        return object.filter({ $0.key == key }).map(\.value)
    }

    public subscript(_ key: String) -> JSON? {
        guard case let .object(object) = self else { return nil }
        return object.first(where: { $0.key == key })?.value
    }
}

// Array

public typealias JSONArray = [JSON]

extension JSON {
    public func arrayValue() throws -> [JSON] {
        guard case let .array(array) = self else { throw JSONError.typeMismatch }
        return array
    }

    public func count() throws -> Int {
        switch self {
        case let .array(array): return array.count
        case let .object(object): return object.count
        default: throw JSONError.typeMismatch
        }
    }

    public func getValue(at index: Int) throws -> JSON {
        guard case let .array(array) = self else { throw JSONError.typeMismatch }
        guard array.indices.contains(index) else { throw JSONError.missingValue }
        return array[index]
    }

    public subscript(_ index: Int) -> JSON {
        (try? getValue(at: index)) ?? .null
    }
}

// Null
extension JSON {
    public var isNull: Bool {
        guard case .null = self else { return false }
        return true
    }
}

// Tuples (JSONKeyValues) can't directly conform to Equatable, so do this by hand
extension JSON: Equatable {
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhs), .string(let rhs)): return lhs == rhs
        case (.number(digits: let lhs), .number(digits: let rhs)): return lhs == rhs
        case (.bool(let lhs), .bool(let rhs)): return lhs == rhs
        case (.object(keyValues: let lhs), .object(keyValues: let rhs)):
            return lhs.count == rhs.count && lhs.elementsEqual(rhs, by: { lhs, rhs in
                lhs.key == rhs.key && lhs.value == rhs.value
            })
        case (.array(let lhs), .array(let rhs)): return lhs == rhs
        case (.null, .null): return true
        default: return false
        }
    }
}

extension JSON: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .string(let string): hasher.combine(string)
        case .number(digits: let digits): hasher.combine(digits)
        case .bool(let value): hasher.combine(value)
        case .object(keyValues: let keyValues):
            for (key, value) in keyValues {
                hasher.combine(key)
                hasher.combine(value)
            }
        case .array(let array): hasher.combine(array)
        case .null: hasher.combine(0)
        }
    }
}

// JSONConvertible

public protocol JSONConvertible {
    func jsonValue() throws -> JSON
}

public protocol LosslessJSONConvertible: JSONConvertible {
    func jsonValue() -> JSON
}

extension String: LosslessJSONConvertible {
    public func jsonValue() -> JSON { .string(self) }
}

extension BinaryInteger {
    public func jsonValue() -> JSON { .number(digits: JSON.formatter.string(for: self)!) }
}

extension Int: LosslessJSONConvertible {}
extension Int8: LosslessJSONConvertible {}
extension Int16: LosslessJSONConvertible {}
extension Int32: LosslessJSONConvertible {}
extension Int64: LosslessJSONConvertible {}
extension UInt: LosslessJSONConvertible {}
extension UInt8: LosslessJSONConvertible {}
extension UInt16: LosslessJSONConvertible {}
extension UInt32: LosslessJSONConvertible {}
extension UInt64: LosslessJSONConvertible {}

extension BinaryFloatingPoint {
    public func jsonValue() -> JSON { .number(digits: JSON.formatter.string(for: self)!) }
}

extension Float: LosslessJSONConvertible {}
extension Double: LosslessJSONConvertible {}

extension Decimal: LosslessJSONConvertible {
    public func jsonValue() -> JSON {
        var decimal = self
        return .number(digits: NSDecimalString(&decimal, nil))
    }
}

extension JSON: LosslessJSONConvertible {
    public func jsonValue() -> JSON { self }
}

extension Bool: LosslessJSONConvertible {
    public func jsonValue() -> JSON { .bool(self) }
}

extension Sequence where Element: LosslessJSONConvertible {
    public func jsonValue() -> JSON { .array(self.map { $0.jsonValue() }) }
}

extension Sequence where Element: JSONConvertible {
    public func jsonValue() throws -> JSON { .array(try self.map { try $0.jsonValue() }) }
}

extension NSArray: JSONConvertible {
    public func jsonValue() throws -> JSON {
        .array(try self.map {
            guard let value = $0 as? JSONConvertible else { throw JSONError.typeMismatch }
            return try value.jsonValue()
        })
    }
}

extension NSDictionary: JSONConvertible {
    public func jsonValue() throws -> JSON {
        guard let dict = self as? [String: JSONConvertible] else { throw JSONError.typeMismatch }
        return try dict.jsonValue()
    }
}

extension Array: LosslessJSONConvertible where Element: LosslessJSONConvertible {}
extension Array: JSONConvertible where Element: JSONConvertible {}

public extension Sequence where Element == (key: String, value: LosslessJSONConvertible) {
    func jsonValue() -> JSON {
        return .object(keyValues: self.map { ($0.key, $0.value.jsonValue()) } )
    }
}

public extension Sequence where Element == (key: String, value: JSONConvertible) {
    func jsonValue() throws -> JSON {
        return .object(keyValues: try self.map { ($0.key, try $0.value.jsonValue()) } )
    }
}

public extension Dictionary where Key == String, Value: LosslessJSONConvertible {
    func jsonValue() -> JSON {
        return .object(keyValues: self.map { ($0.key, $0.value.jsonValue()) } )
    }
}

public extension Dictionary where Key == String, Value: JSONConvertible {
    func jsonValue() throws -> JSON {
        return .object(keyValues: try self.map { ($0.key, try $0.value.jsonValue()) } )
    }
}

extension JSONTokenString: JSONConvertible {
    public func jsonValue() throws -> JSON {
        guard let string = self.contents?
                .replacingOccurrences(of: "\\\\", with: "\\")
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\/", with: "/")
                .replacingOccurrences(of: "\\b", with: "\u{8}")
                .replacingOccurrences(of: "\\f", with: "\u{c}")
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\r", with: "\r")
                .replacingOccurrences(of: "\\t", with: "\t")
        // TODO: Support \u syntax
        else { throw JSONError.dataCorrupted }
        return .string(string)
    }
}

extension JSONTokenNumber: JSONConvertible {
    public func jsonValue() throws -> JSON {
        // FIXME: Validate digitString
        guard let digits = String(data: self.data, encoding: .utf8) else { throw JSONError.dataCorrupted }
        return .number(digits: digits)
    }
}

//
//extension JSONObject: Collection {
//    public struct ObjectIndex: Comparable {
//        public static func < (lhs: JSONObject.ObjectIndex, rhs: JSONObject.ObjectIndex) -> Bool {
//            lhs.value < rhs.value
//        }
//        fileprivate let value: Int
//    }
//    public var startIndex: ObjectIndex { ObjectIndex(value: keyValues.startIndex) }
//    public var endIndex: ObjectIndex { ObjectIndex(value: keyValues.endIndex) }
//    public func index(after i: ObjectIndex) -> ObjectIndex { ObjectIndex(value: keyValues.index(after: i.value)) }
//    public subscript(position: ObjectIndex) -> (key: String, value: JSONValue) {
//        get { keyValues[position.value] }
//        set { keyValues[position.value] = newValue }
//    }
//}
//
//public struct JSONArray: JSONValue {
//    public var elements: [JSONValue]
//    public init(_ elements: [JSONValue] = []) { self.elements = elements }
//    public init(_ array: NSArray) throws { self.init(try array.map { try $0 as? JSONValue ?? makeJSON(fromAny: $0) } ) }
//    public mutating func append(_ element: JSONValue) {
//        elements.append(element)
//    }
//    public var count: Int { elements.count }
//    public func get(_ index: Int) throws -> JSONValue {
//        if elements.indices.contains(index) {
//            return elements[index]
//        } else {
//            throw JSONError.missingValue
//        }
//    }
//}
//
//extension JSONArray: Collection {
//    public var startIndex: Int { elements.startIndex }
//    public var endIndex: Int { elements.endIndex }
//    public func index(after i: Int) -> Int { i + 1 }
//    public subscript(position: Int) -> JSONValue {
//        (try? get(position)) ?? JSONNull()
//    }
//}
