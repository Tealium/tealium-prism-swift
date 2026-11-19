//
//  XCTAssert+Errors.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 01/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

enum TestError: Error, Equatable {
    case fileNotFound(named: String)
    case unknown
}

func XCTAssertTestErrorEquals(
    _ testError: Error,
    _ other: TestError,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let testError = testError as? TestError else {
        XCTFail("Underlying error is not a TestError \(testError)", file: file, line: line)
        return
    }
    XCTAssertEqual(testError, other, file: file, line: line)
}

func XCTAssertModuleShutdown<Failure: Error>(
    _ error: Error,
    wrapping type: Failure.Type = Error.self,
    module expectedModule: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let moduleError = error as? ModuleError<Failure>,
          case .moduleShutdown(let module) = moduleError else {
        XCTFail("Expected ModuleError.moduleShutdown but got \(error)", file: file, line: line)
        return
    }
    XCTAssertEqual(module, expectedModule, file: file, line: line)
}

func XCTAssertNetworkError(
    _ networkError: NetworkError,
    equalsURLErrorWith underlyingError: Error?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let underlyingError = underlyingError as? URLError else {
        XCTFail("Underlying error is not an URLError \(underlyingError as Any)", file: file, line: line)
        return
    }

    guard case let .urlError(urlError) = networkError.type else {
        XCTFail("NetworkError is not an URLError \(networkError.type)", file: file, line: line)
        return
    }

    XCTAssertEqual(urlError.code, underlyingError.code, file: file, line: line)
}

func XCTAssertNetworkError(
    _ networkError: NetworkErrorType,
    equalsNon200StatusErrorWith code: Int,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard case let .non200Status(actual, _) = networkError else {
        XCTFail("NetworkError is not an non200Status \(networkError)", file: file, line: line)
        return
    }

    XCTAssertEqual(actual, code, file: file, line: line)
}

enum NetworkErrorSimplifiedType: String, Error {
    case non200Status
    case cancelled
    case urlError
    case unknown
}

func XCTAssertNetworkError(
    _ networkError: Error,
    is type: NetworkErrorSimplifiedType,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let networkError = networkError as? NetworkError else {
        XCTFail("Expected NetworkError but got \(networkError)", file: file, line: line)
        return
    }
    XCTAssertNetworkErrorType(networkError.type, is: type, file: file, line: line)
}

func XCTAssertNetworkErrorType(
    _ networkError: Error,
    is type: NetworkErrorSimplifiedType,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let networkError = networkError as? NetworkErrorType else {
        XCTFail("Expected NetworkErrorType but got \(networkError)", file: file, line: line)
        return
    }
    switch (networkError, type) {
    case (.non200Status, .non200Status),
        (.cancelled, .cancelled),
        (.urlError, .urlError),
        (.unknown, .unknown): break
    default:
        XCTFail("\(networkError) is not of type \(type.rawValue)", file: file, line: line)
    }
}

func XCTAssertThrows<T, E: Error>(_ expression: @autoclosure () throws(E) -> T,
                                  _ message: @autoclosure () -> String = "",
                                  file: StaticString = #filePath,
                                  line: UInt = #line,
                                  _ errorHandler: (_ error: E) -> Void = { _ in }) {
    do {
        _ = try expression()
        XCTFail("Expression expected to throw but succeeded instead", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}

private struct NothingThrown: Error { }

/// The error `block` throws. Fails the test and throws if `block` doesn't throw.
func XCTUnwrapThrownError<T>(_ block: () throws -> T, file: StaticString = #filePath, line: UInt = #line) throws -> Error {
    do {
        _ = try block()
    } catch {
        return error
    }
    XCTFail("No error thrown", file: file, line: line)
    throw NothingThrown()
}

/// Asserts that `error` is `DatabaseError.connectionClosed`, never corruption itself, and describes its cause.
/// The cause is the corruption `original` (same SQLite code and message) or, without it, any error that
/// `DatabaseHelper.corruptionCode` treats as corruption: `SQLITE_CORRUPT` or `SQLITE_NOTADB`, in primary or extended form.
func XCTAssertConnectionClosed(
    _ error: Error,
    causedBy original: Error? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard case let DatabaseError.connectionClosed(cause) = error else {
        XCTFail("\(error) is not DatabaseError.connectionClosed", file: file, line: line)
        return
    }
    XCTAssertNil(DatabaseHelper.corruptionCode(error), "The closed error must never be corruption itself", file: file, line: line)
    XCTAssertTrue("\(error)".contains("\(cause)"), "The description of \(error) has no cause", file: file, line: line)
    guard let original else {
        XCTAssertNotNil(DatabaseHelper.corruptionCode(cause), "\(cause) is not a corruption error", file: file, line: line)
        return
    }
    XCTAssertNotNil(DatabaseHelper.corruptionCode(cause), file: file, line: line)
    XCTAssertEqual(DatabaseHelper.corruptionCode(cause), DatabaseHelper.corruptionCode(original), file: file, line: line)
    XCTAssertEqual("\(cause)", "\(original)", file: file, line: line)
}
