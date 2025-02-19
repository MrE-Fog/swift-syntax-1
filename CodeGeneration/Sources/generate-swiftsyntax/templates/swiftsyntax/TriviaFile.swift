//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxBuilder
import SyntaxSupport
import Utils

let triviaFile = SourceFileSyntax(leadingTrivia: copyrightHeader) {
  DeclSyntax(
    """
    public enum TriviaPosition {
      case leading
      case trailing
    }
    """
  )

  try! EnumDeclSyntax(
    """
    /// A contiguous stretch of a single kind of trivia. The constituent part of
    /// a `Trivia` collection.
    ///
    /// For example, four spaces would be represented by
    /// `.spaces(4)`
    ///
    /// In general, you should deal with the actual Trivia collection instead
    /// of individual pieces whenever possible.
    public enum TriviaPiece
    """
  ) {
    for trivia in TRIVIAS {
      if trivia.isCollection {
        DeclSyntax(
          """
          /// \(raw: trivia.comment)
          case \(raw: trivia.enumCaseName)(Int)
          """
        )

      } else {
        DeclSyntax(
          """
          /// \(raw: trivia.comment)
          case \(raw: trivia.enumCaseName)(String)
          """
        )
      }
    }
  }

  try! ExtensionDeclSyntax("extension TriviaPiece: TextOutputStreamable") {
    try FunctionDeclSyntax(
      """
      /// Prints the provided trivia as they would be written in a source file.
      ///
      /// - Parameter stream: The stream to which to print the trivia.
      public func write<Target>(to target: inout Target) where Target: TextOutputStream
      """
    ) {
      DeclSyntax(
        """
        func printRepeated(_ character: String, count: Int) {
          for _ in 0..<count { target.write(character) }
        }
        """
      )

      try SwitchExprSyntax("switch self") {
        for trivia in TRIVIAS {
          if trivia.isCollection {
            let joined = trivia.characters.map { "\($0)" }.joined()
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(count):") {
              ExprSyntax("printRepeated(\(literal: joined), count: count)")
            }
          } else {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(text):") {
              ExprSyntax("target.write(text)")
            }
          }
        }
      }
    }
  }

  try! ExtensionDeclSyntax("extension TriviaPiece: CustomDebugStringConvertible") {
    try VariableDeclSyntax(
      """
      /// Returns a description used by dump.
      public var debugDescription: String
      """
    ) {
      try SwitchExprSyntax("switch self") {
        for trivia in TRIVIAS {
          if trivia.isCollection {
            SwitchCaseSyntax("case .\(raw: trivia.enumCaseName)(let data):") {
              StmtSyntax(#"return "\#(raw: trivia.enumCaseName)(\(data))""#)
            }
          } else {
            SwitchCaseSyntax("case .\(raw: trivia.enumCaseName)(let name):") {
              StmtSyntax(#"return "\#(raw: trivia.enumCaseName)(\(name.debugDescription))""#)
            }
          }
        }
      }
    }
  }

  DeclSyntax(
    """
    extension TriviaPiece {
      /// Returns true if the trivia is `.newlines`, `.carriageReturns` or `.carriageReturnLineFeeds`
      public var isNewline: Bool {
        switch self {
        case .newlines,
            .carriageReturns,
            .carriageReturnLineFeeds:
          return true
        default:
          return false
        }
      }
    }
    """
  )

  try! StructDeclSyntax(
    """
    /// A collection of leading or trailing trivia. This is the main data structure
    /// for thinking about trivia.
    public struct Trivia
    """
  ) {
    DeclSyntax("public let pieces: [TriviaPiece]")

    DeclSyntax(
      """
      /// Creates Trivia with the provided underlying pieces.
      public init<S: Sequence>(pieces: S) where S.Element == TriviaPiece {
        self.pieces = Array(pieces)
      }
      """
    )

    DeclSyntax(
      """
      /// Creates Trivia with no pieces.
      public static var zero: Trivia {
        return Trivia(pieces: [])
      }
      """
    )

    DeclSyntax(
      """
      /// Whether the Trivia contains no pieces.
      public var isEmpty: Bool {
        pieces.isEmpty
      }
      """
    )

    DeclSyntax(
      """
      /// Creates a new `Trivia` by appending the provided `TriviaPiece` to the end.
      public func appending(_ piece: TriviaPiece) -> Trivia {
        var copy = pieces
        copy.append(piece)
        return Trivia(pieces: copy)
      }
      """
    )

    DeclSyntax(
      """
      public var sourceLength: SourceLength {
        return pieces.map({ $0.sourceLength }).reduce(.zero, +)
      }
      """
    )

    DeclSyntax(
      """
      /// Get the byteSize of this trivia
      public var byteSize: Int {
        return sourceLength.utf8Length
      }
      """
    )

    for trivia in TRIVIAS {
      if trivia.isCollection {
        let joined = trivia.characters.map { "\($0)" }.joined()
        DeclSyntax(
          """
          /// Returns a piece of trivia for some number of \(literal: joined) characters.
          public static func \(raw: trivia.enumCaseName)(_ count: Int) -> Trivia {
            return [.\(raw: trivia.enumCaseName)(count)]
          }
          """
        )

        DeclSyntax(
          """
          /// Gets a piece of trivia for \(literal: joined) characters.
          public static var \(raw: trivia.lowerName): Trivia {
            return .\(raw: trivia.enumCaseName)(1)
          }
          """
        )

      } else {
        DeclSyntax(
          """
          /// Returns a piece of trivia for \(raw: trivia.name).
          public static func \(raw: trivia.enumCaseName)(_ text: String) -> Trivia {
            return [.\(raw: trivia.enumCaseName)(text)]
          }
          """
        )
      }
    }
  }

  DeclSyntax(
    #"""
    extension Trivia: CustomDebugStringConvertible {
      public var debugDescription: String {
        if count == 1, let first = first {
          return first.debugDescription
        }
        return "[" + map(\.debugDescription).joined(separator: ", ") + "]"
      }
    }
    """#
  )

  DeclSyntax("extension Trivia: Equatable {}")

  DeclSyntax(
    """
    /// Conformance for Trivia to the Collection protocol.
    extension Trivia: Collection {
      public var startIndex: Int {
        return pieces.startIndex
      }

      public var endIndex: Int {
        return pieces.endIndex
      }

      public func index(after i: Int) -> Int {
        return pieces.index(after: i)
      }

      public subscript(_ index: Int) -> TriviaPiece {
        return pieces[index]
      }
    }
    """
  )

  DeclSyntax(
    """
    extension Trivia: ExpressibleByArrayLiteral {
      /// Creates Trivia from the provided pieces.
      public init(arrayLiteral elements: TriviaPiece...) {
        self.pieces = elements
      }
    }
    """
  )

  DeclSyntax(
    """
    extension Trivia: TextOutputStreamable {
      /// Prints the provided trivia as they would be written in a source file.
      ///
      /// - Parameter stream: The stream to which to print the trivia.
      public func write<Target>(to target: inout Target)
      where Target: TextOutputStream {
        for piece in pieces {
          piece.write(to: &target)
        }
      }
    }
    """
  )

  DeclSyntax(
    """
    extension Trivia: CustomStringConvertible {
      public var description: String {
        var description = ""
        self.write(to: &description)
        return description
      }
    }
    """
  )

  DeclSyntax(
    """
    extension Trivia {
      /// Concatenates two collections of `Trivia` into one collection.
      public static func +(lhs: Trivia, rhs: Trivia) -> Trivia {
        return Trivia(pieces: lhs.pieces + rhs.pieces)
      }

      /// Concatenates two collections of `Trivia` into the left-hand side.
      public static func +=(lhs: inout Trivia, rhs: Trivia) {
        lhs = lhs + rhs
      }
    }
    """
  )

  DeclSyntax("extension TriviaPiece: Equatable {}")

  try! ExtensionDeclSyntax("extension TriviaPiece") {
    try VariableDeclSyntax("public var sourceLength: SourceLength") {
      try SwitchExprSyntax("switch self") {
        for trivia in TRIVIAS {
          if trivia.isCollection {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(count):") {
              if trivia.charactersLen != 1 {
                StmtSyntax("return SourceLength(utf8Length: count * \(raw: trivia.charactersLen))")
              } else {
                StmtSyntax("return SourceLength(utf8Length: count)")
              }
            }
          } else {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(text):") {
              StmtSyntax("return SourceLength(of: text)")
            }
          }
        }
      }
    }
  }

  try! EnumDeclSyntax(
    """
    /// Trivia piece for token RawSyntax.
    ///
    /// In contrast to `TriviaPiece`, a `RawTriviaPiece` does not own the source
    /// text of a the trivia.
    @_spi(RawSyntax)
    public enum RawTriviaPiece: Equatable
    """
  ) {
    for trivia in TRIVIAS {
      if trivia.isCollection {
        DeclSyntax(" case \(raw: trivia.enumCaseName)(Int)")

      } else {
        DeclSyntax("case \(raw: trivia.enumCaseName)(SyntaxText)")
      }
    }

    try FunctionDeclSyntax(
      """
      static func make(_ piece: TriviaPiece, arena: SyntaxArena) -> RawTriviaPiece
      """
    ) {
      try SwitchExprSyntax("switch piece") {
        for trivia in TRIVIAS {
          if trivia.isCollection {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(count):") {
              StmtSyntax("return .\(raw: trivia.enumCaseName)(count)")
            }
          } else {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(text):") {
              StmtSyntax("return .\(raw: trivia.enumCaseName)(arena.intern(text))")
            }
          }
        }
      }
    }
  }

  DeclSyntax(
    """
    extension RawTriviaPiece: TextOutputStreamable {
      public func write<Target: TextOutputStream>(to target: inout Target) {
        TriviaPiece(raw: self).write(to: &target)
      }
    }
    """
  )

  DeclSyntax(
    """
    extension RawTriviaPiece: CustomDebugStringConvertible {
      public var debugDescription: String {
        TriviaPiece(raw: self).debugDescription
      }
    }
    """
  )

  try! ExtensionDeclSyntax("extension TriviaPiece") {
    try InitializerDeclSyntax("@_spi(RawSyntax) public init(raw: RawTriviaPiece)") {
      try SwitchExprSyntax("switch raw") {
        for trivia in TRIVIAS {
          if trivia.isCollection {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(count):") {
              ExprSyntax("self = .\(raw: trivia.enumCaseName)(count)")
            }
          } else {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(text):") {
              ExprSyntax("self = .\(raw: trivia.enumCaseName)(String(syntaxText: text))")
            }
          }
        }
      }
    }
  }

  try! ExtensionDeclSyntax("extension RawTriviaPiece") {
    try VariableDeclSyntax("public var byteLength: Int") {
      try SwitchExprSyntax("switch self") {
        for trivia in TRIVIAS {
          if trivia.isCollection {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(count):") {
              if trivia.charactersLen != 1 {
                StmtSyntax("return count * \(raw: trivia.charactersLen)")
              } else {
                StmtSyntax("return count")
              }
            }
          } else {
            SwitchCaseSyntax("case let .\(raw: trivia.enumCaseName)(text):") {
              StmtSyntax("return text.count")
            }
          }
        }
      }
    }

    try VariableDeclSyntax("var storedText: SyntaxText?") {
      try SwitchExprSyntax("switch self") {
        for trivia in TRIVIAS {
          if trivia.isCollection {
            SwitchCaseSyntax("case .\(raw: trivia.enumCaseName)(_):") {
              StmtSyntax("return nil")
            }
          } else {
            SwitchCaseSyntax("case .\(raw: trivia.enumCaseName)(let text):") {
              StmtSyntax("return text")
            }
          }
        }
      }
    }
  }

  DeclSyntax(
    """
    extension RawTriviaPiece {
      /// Returns true if the trivia is `.newlines`, `.carriageReturns` or `.carriageReturnLineFeeds`
      public var isNewline: Bool {
        switch self {
        case .newlines,
            .carriageReturns,
            .carriageReturnLineFeeds:
          return true
        default:
          return false
        }
      }
    }
    """
  )
}
