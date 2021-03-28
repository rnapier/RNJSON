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

public struct JSONMetadataKey: Hashable, RawRepresentable {
    static let leadingWhitespace  = JSONMetadataKey("RNJSON.leadingWhitespace")
    static let trailingWhitespace = JSONMetadataKey("RNJSON.trailingWhitespace")

    public let rawValue: String
    public init(_ rawValue: String) { self.init(rawValue: rawValue )}
    public init(rawValue: String) { self.rawValue = rawValue }
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

    var metadata: [JSONMetadataKey: Any] { get }
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

    public var metadata: [JSONMetadataKey: Any] = [:]

    public init(_ token: JSONTokenString) throws {
        // FIXME: Validate
        guard let string = token.contents else { throw JSONError.dataCorrupted }
        self.init(string)
    }
}

public struct JSONNumber: JSONValue {
    public var digitString: String
    public init<Number: FixedWidthInteger>(_ number: Number) { self.digitString = "\(number)" }

    public var metadata: [JSONMetadataKey: Any] = [:]

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
    public var metadata: [JSONMetadataKey: Any] = [:]
    public init(_ value: Bool) { self.value = value }
    public func boolValue() throws -> Bool { value }
}

public struct JSONObject: JSONValue {
    public var keyValues: [(key: String, value: JSONValue)]
    public var metadata: [JSONMetadataKey: Any] = [:]
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
    public var metadata: [JSONMetadataKey: Any] = [:]
    public init(_ elements: [JSONValue] = []) { self.elements = elements }
    public mutating func append(_ element: JSONValue) {
        elements.append(element)
    }
    public var count: Int { elements.count }
    public func get(_ index: Int) throws -> JSONValue { try self[index] ?? { throw JSONError.missingValue }() }
    public subscript(_ index: Int) -> JSONValue? { elements.indices.contains(index) ? elements[index] : nil }
}

public struct JSONNull: JSONValue {
    public var metadata: [JSONMetadataKey: Any] = [:]
    public var isNull: Bool { true }
}
