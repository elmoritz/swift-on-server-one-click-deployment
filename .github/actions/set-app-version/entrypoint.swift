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
guard CommandLine.arguments.count == 3 else {
    exitWithError("Usage: \(CommandLine.arguments[0]) <version> <environment>")
}

let version = CommandLine.arguments[1]
let environment = CommandLine.arguments[2]

let appVersionPath = "todos-fluent/Sources/App/AppVersion.swift"

log("Setting version to \(version) for environment \(environment)")

// Get current date in ISO8601 format
let dateFormatter = ISO8601DateFormatter()
let buildDate = dateFormatter.string(from: Date())

// Create new AppVersion.swift content
let newContent = """
// AppVersion.swift
// This file contains hardcoded version information
// It is automatically generated during the build process

enum AppVersion {
    // MARK: - Version Information
    // These values are set by the CI/CD pipeline during build

    /// Current application version
    /// Format: MAJOR.MINOR.PATCH.BUILD for staging (e.g., 0.1.0.42)
    /// Format: MAJOR.MINOR.PATCH for production (e.g., 1.2.3)
    static let current = "\(version)"

    /// Build date in ISO8601 format
    static let buildDate = "\(buildDate)"

    /// Environment (staging or production)
    static let environment = "\(environment)"
}
"""

do {
    try newContent.write(toFile: appVersionPath, atomically: true, encoding: .utf8)
    log("✅ Version updated successfully")
    log("   Version: \(version)")
    log("   Build date: \(buildDate)")
    log("   Environment: \(environment)")
} catch {
    exitWithError("Failed to write AppVersion.swift: \(error)")
}
