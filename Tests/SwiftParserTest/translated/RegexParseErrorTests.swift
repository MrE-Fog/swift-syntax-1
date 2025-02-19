//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// This test file has been translated from swift/test/StringProcessing/Parse/regex_parse_error.swift

import XCTest

final class RegexParseErrorTests: XCTestCase {
  func testRegexParseError1() {
    assertParse(
      """
      _ = /(/
      """
    )
  }

  func testRegexParseError2() {
    assertParse(
      """
      _ = #/(/#
      """
    )
  }

  func testRegexParseError4() {
    assertParse(
      """
      _ = /)/
      """
    )
  }

  func testRegexParseError5() {
    assertParse(
      """
      _ = #/)/#
      """
    )
  }

  func testRegexParseError6() {
    assertParse(
      #"""
      _ = #/\\/''/1️⃣
      """#,
      diagnostics: [
        DiagnosticSpec(message: "expected '#' to end regex literal")
      ]
    )
  }

  func testRegexParseError7() {
    assertParse(
      #"""
      _ = #/\|1️⃣
      """#,
      diagnostics: [
        DiagnosticSpec(message: "expected '/#' to end regex literal")
      ]
    )
  }

  func testRegexParseError8() {
    assertParse(
      """
      _ = #//1️⃣
      """,
      diagnostics: [
        DiagnosticSpec(message: "expected '#' to end regex literal")
      ]
    )
  }

  func testRegexParseError9() {
    assertParse(
      """
      _ = #/xy1️⃣
      """,
      diagnostics: [
        DiagnosticSpec(message: "expected '/#' to end regex literal")
      ]
    )
  }

  func testRegexParseError10() {
    assertParse(
      """
      _ = #/(?/#
      """
    )
  }

  func testRegexParseError11() {
    assertParse(
      """
      _ = #/(?'/#
      """
    )
  }

  func testRegexParseError12() {
    assertParse(
      """
      _ = #/(?'abc/#
      """
    )
  }

  func testRegexParseError13() {
    assertParse(
      """
      _ = #/(?'abc /#
      """
    )
  }

  func testRegexParseError14() {
    assertParse(
      """
      do {
        _ = #/(?'a1️⃣
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "expected '/#' to end regex literal")
      ]
    )
  }

  func testRegexParseError15() {
    assertParse(
      #"""
      _ = #/\(?'abc/#
      """#
    )
  }

  func testRegexParseError16() {
    assertParse(
      #"""
      do {
        _ = /\1️⃣
        /2️⃣
      }
      """#,
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "expected root in key path"),
        DiagnosticSpec(locationMarker: "2️⃣", message: "expected expression after operator"),
      ]
    )
  }

  func testRegexParseError17() {
    assertParse(
      #"""
      do {
        _ = #/\1️⃣
      /#2️⃣
      }
      """#,
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "expected '/#' to end regex literal"),
        DiagnosticSpec(locationMarker: "2️⃣", message: "expected identifier in macro expansion"),
      ]
    )
  }

  func testRegexParseError19() {
    assertParse(
      """
      foo(#/(?/#, #/abc/#) 
      foo(#/(?C/#, #/abc/#)
      """
    )
  }

  func testRegexParseError20() {
    assertParse(
      """
      foo(#/(?'/#, #/abc/#)
      """
    )
  }
}
