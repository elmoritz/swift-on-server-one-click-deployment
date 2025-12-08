#!/usr/bin/env swift
import Foundation

// MARK: - Logging
func log(_ message: String) {
    print("[set-app-version] \(message)")
}

func exitWithError(_ message: String) -> Never {
    if let data = ("❌ [ERROR] \(message)\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
    exit(1)
}

// MARK: - Main Logic
guard CommandLine.arguments.count == 4 else {
    exitWithError("Usage: \(CommandLine.arguments[0]) <version> <build-number> <environment>")
}

let version = CommandLine.arguments[1]
let buildNumber = CommandLine.arguments[2]
let environment = CommandLine.arguments[3]

let appVersionPath = "todos-fluent/Sources/App/Models/AppVersion.swift"

log("Setting version to \(version), build number \(buildNumber) for environment \(environment)")

// Create new AppVersion.swift content
let newContent = """
// AppVersion.swift
// This file contains hardcoded version information
// It is automatically modified during the CI/CD build process

import Hummingbird

/// Application version information
enum AppVersion {
    // MARK: - Version Information
    // These values are set by the CI/CD pipeline during build

    /// Semantic version from git tags (e.g., "1.0.0")
    static let version = "\(version)"

    /// Build number from commit count to main branch (e.g., "42")
    static let buildNumber = "\(buildNumber)"

    /// Environment (development, staging, or production)
    static let environment = "\(environment)"
}

/// Response structure for version endpoint
struct AppVersionResponse: ResponseCodable {
    /// Semantic version from git tags
    let version: String

    /// Build number from commit count
    let buildNumber: String

    /// Environment (development, staging, or production)
    let environment: String
}
"""

do {
    try newContent.write(toFile: appVersionPath, atomically: true, encoding: .utf8)
    log("✅ Version updated successfully")
    log("   Version: \(version)")
    log("   Build number: \(buildNumber)")
    log("   Environment: \(environment)")
} catch {
    exitWithError("Failed to write AppVersion.swift: \(error)")
}
