//
// This is a derived work from STdlibUnittest.swift from the Swift stdlib with
// modifications to use RNJSON.
//
// The following is the original copyright notice from Swift stdlib:

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest   // RNJSON

public struct SourceLoc {
  public let file: String
  public let line: UInt
  public let comment: String?

  public init(_ file: String, _ line: UInt, comment: String? = nil) {
    self.file = file
    self.line = line
    self.comment = comment
  }

  public func withCurrentLoc(
    _ file: String = #file, line: UInt = #line
  ) -> SourceLocStack {
    return SourceLocStack(self).with(SourceLoc(file, line))
  }
}

public struct SourceLocStack {
  let locs: [SourceLoc]

  public init() {
    locs = []
  }

  public init(_ loc: SourceLoc) {
    locs = [loc]
  }

  init(_locs: [SourceLoc]) {
    locs = _locs
  }

  var isEmpty: Bool {
    return locs.isEmpty
  }

  public func with(_ loc: SourceLoc) -> SourceLocStack {
    var locs = self.locs
    locs.append(loc)
    return SourceLocStack(_locs: locs)
  }

  public func pushIf(
    _ showFrame: Bool, file: String, line: UInt
  ) -> SourceLocStack {
    return showFrame ? self.with(SourceLoc(file, line)) : self
  }

  public func withCurrentLoc(
    file: String = #file, line: UInt = #line
  ) -> SourceLocStack {
    return with(SourceLoc(file, line))
  }

  public func print() {
    let top = locs.first!
    Swift.print("check failed at \(top.file), line \(top.line)")
    _printStackTrace(SourceLocStack(_locs: Array(locs.dropFirst())))
  }
}

public func expectUnreachable(
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  expectationFailure("this code should not be executed", trace: message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line))
}

func _printStackTrace(_ stackTrace: SourceLocStack?) {
  guard let s = stackTrace, !s.locs.isEmpty else { return }
  print("stacktrace:")
  for (i, loc) in s.locs.reversed().enumerated() {
    let comment = (loc.comment != nil) ? " ; \(loc.comment!)" : ""
    print("  #\(i): \(loc.file):\(loc.line)\(comment)")
  }
}

//fileprivate var _anyExpectFailed = AtomicBool(false)

//fileprivate struct AtomicBool {
//
//    private var _value: _stdlib_AtomicInt
//
//    init(_ b: Bool) { self._value = _stdlib_AtomicInt(b ? 1 : 0) }
//
//    func store(_ b: Bool) { _value.store(b ? 1 : 0) }
//
//    func load() -> Bool { return _value.load() != 0 }
//
//    @discardableResult
//    func orAndFetch(_ b: Bool) -> Bool {
//        return _value.orAndFetch(b ? 1 : 0) != 0
//    }
//
//    func fetchAndClear() -> Bool {
//        return _value.fetchAndAnd(0) != 0
//    }
//}

public func expectationFailure(
  _ reason: String,
  trace message: String,
  stackTrace: SourceLocStack) {
//  _anyExpectFailed.store(true)
  stackTrace.print()
  print(reason, terminator: reason == "" ? "" : "\n")
  print(message, terminator: message == "" ? "" : "\n")
    // RNJSON
    XCTFail(message)
    //
}

public func expectEqual<T : Equatable>(_ expected: T, _ actual: T,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  expectEqualTest(expected, actual, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
}

public func expectEqual<T : Equatable, U : Equatable>(
  _ expected: (T, U), _ actual: (T, U),
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  expectEqualTest(expected.0, actual.0, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
  expectEqualTest(expected.1, actual.1, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
}

public func expectEqual<T : Equatable, U : Equatable, V : Equatable>(
  _ expected: (T, U, V), _ actual: (T, U, V),
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  expectEqualTest(expected.0, actual.0, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
  expectEqualTest(expected.1, actual.1, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
  expectEqualTest(expected.2, actual.2, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
}

public func expectEqual<T : Equatable, U : Equatable, V : Equatable, W : Equatable>(
  _ expected: (T, U, V, W), _ actual: (T, U, V, W),
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  expectEqualTest(expected.0, actual.0, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
  expectEqualTest(expected.1, actual.1, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
  expectEqualTest(expected.2, actual.2, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
  expectEqualTest(expected.3, actual.3, message(),
    stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) {$0 == $1}
}

public func expectEqual(_ expected: String, _ actual: Substring,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  if !(expected == actual) {
    expectationFailure(
      "expected: \(String(reflecting: expected)) (of type \(String(reflecting: type(of: expected))))\n"
      + "actual: \(String(reflecting: actual)) (of type \(String(reflecting: type(of: actual))))",
      trace: message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line)
    )
  }
}
public func expectEqual(_ expected: Substring, _ actual: String,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  if !(expected == actual) {
    expectationFailure(
      "expected: \(String(reflecting: expected)) (of type \(String(reflecting: type(of: expected))))\n"
      + "actual: \(String(reflecting: actual)) (of type \(String(reflecting: type(of: actual))))",
      trace: message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line)
    )
  }
}
public func expectEqual(_ expected: String, _ actual: String,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  if !(expected == actual) {
    expectationFailure(
      "expected: \(String(reflecting: expected)) (of type \(String(reflecting: type(of: expected))))\n"
      + "actual: \(String(reflecting: actual)) (of type \(String(reflecting: type(of: actual))))",
      trace: message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line)
    )
  }
}

public func expectEqual(
  _ expected: Any.Type, _ actual: Any.Type,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line
) {
  expectEqualTest(expected, actual, message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line), showFrame: false) { $0 == $1 }
}

public func expectEqualTest<T>(
  _ expected: T, _ actual: T,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line, sameValue equal: (T, T) -> Bool
) {
  if !equal(expected, actual) {
    expectationFailure(
      "expected: \(String(reflecting: expected)) (of type \(String(reflecting: type(of: expected))))\n"
      + "actual: \(String(reflecting: actual)) (of type \(String(reflecting: type(of: actual))))",
      trace: message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line)
    )
  }
}

public func expectTrue(_ actual: AssertionResult,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  if !actual._isPass {
    expectationFailure(
      "expected: passed assertion\n\(actual.description)", trace: message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line))
  }
}

public func expectTrue(_ actual: Bool,
  _ message: @autoclosure () -> String = "",
  stackTrace: SourceLocStack = SourceLocStack(),
  showFrame: Bool = true,
  file: String = #file, line: UInt = #line) {
  if !actual {
    expectationFailure("expected: true", trace: message(),
      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line))
  }
}

public struct AssertionResult : CustomStringConvertible {
  init(isPass: Bool) {
    self._isPass = isPass
  }

  public func withDescription(_ description: String) -> AssertionResult {
    var result = self
    result.description += description
    return result
  }

  let _isPass: Bool

  public var description: String = ""
}
