# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

add_swift_host_library(SwiftCompilerPluginMessageHandling
  CompilerPluginMessageHandler.swift
  Diagnostics.swift
  Macros.swift
  PluginMacroExpansionContext.swift
  PluginMessages.swift
)

target_link_libraries(SwiftCompilerPluginMessageHandling PUBLIC
  SwiftSyntax
  SwiftDiagnostics
  SwiftParser
  SwiftSyntaxMacros
  SwiftOperators)
