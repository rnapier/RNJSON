import Foundation

// MARK: - Errors
public enum JSONError: Swift.Error {
    case unexpectedByte(at: Int, found: [UInt8])
    case unexpectedToken(at: Int, expected: [JSONToken.Type], found: JSONToken)
    case unknownValue(JSONValue)
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

    var isNull: Bool { get }
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

    var isNull: Bool { false }
}

public struct JSONString: JSONValue {
    public var string: String
    public init(_ string: String) { self.string = string }
    public func stringValue() throws -> String { string }

    public init(_ token: JSONTokenString) throws {
        // FIXME: Validate string
        guard let string = token.contents else { throw JSONError.dataCorrupted }
        self.init(string)
    }
}

public struct JSONNumber: JSONValue {
    public var digitString: String
    public init<Number: Numeric>(_ number: Number) { self.digitString = "\(number)" }

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
    public init(_ keyValues: [(key: String, value: JSONValue)] = []) { self.keyValues = keyValues }
    public mutating func add(value: JSONValue, for key: String) {
        keyValues.append((key: key, value: value))
    }

    public var count: Int { keyValues.count }
    public func get(_ key: String) throws -> JSONValue { try self[key] ?? { throw JSONError.missingValue }() }
    public func getAll(_ key: String) -> [JSONValue] { keyValues.filter({ $0.key == key }).map(\.value) }

    public subscript(_ key: String) -> JSONValue? {
        get { keyValues.first(where: { $0.key == key })?.value }
        set {
            if let value = newValue {
                if let index = keyValues.firstIndex(where: { $0.key == key}) {
                    keyValues[index] = (key: key, value: value)
                } else {
                    keyValues.append((key: key, value: value))
                }
            } else {
                if let index = keyValues.firstIndex(where: { $0.key == key }) {
                    keyValues.remove(at: index)
                }
            }
        }
    }

    public var keys: [String] { keyValues.map(\.key) }
}

extension JSONObject: Collection {
    public struct ObjectIndex: Comparable {
        public static func < (lhs: JSONObject.ObjectIndex, rhs: JSONObject.ObjectIndex) -> Bool {
            lhs.value < rhs.value
        }
        fileprivate let value: Int
    }
    public var startIndex: ObjectIndex { ObjectIndex(value: keyValues.startIndex) }
    public var endIndex: ObjectIndex { ObjectIndex(value: keyValues.endIndex) }
    public func index(after i: ObjectIndex) -> ObjectIndex { ObjectIndex(value: keyValues.index(after: i.value)) }
    public subscript(position: ObjectIndex) -> (key: String, value: JSONValue) {
        get { keyValues[position.value] }
        set { keyValues[position.value] = newValue }
    }
}

public struct JSONArray: JSONValue {
    public var elements: [JSONValue]
    public init(_ elements: [JSONValue] = []) { self.elements = elements }
    public mutating func append(_ element: JSONValue) {
        elements.append(element)
    }
    public var count: Int { elements.count }
    public func get(_ index: Int) throws -> JSONValue { try self[index] ?? { throw JSONError.missingValue }() }
}

extension JSONArray: Collection {
    public var startIndex: Int { elements.startIndex }
    public var endIndex: Int { elements.endIndex }
    public func index(after i: Int) -> Int { i + 1 }
    public subscript(position: Int) -> JSONValue { elements[position] }
}

public struct JSONNull: JSONValue {
    public var isNull: Bool { true }
}
