// AppVersion.swift
// This file contains hardcoded version information
// It is automatically modified during the CI/CD build process

import Hummingbird

/// Application version information
enum AppVersion {
    // MARK: - Version Information
    // These values are set by the CI/CD pipeline during build

    /// Semantic version from git tags (e.g., "1.0.0")
    static let version = "0.0.0"

    /// Build number from commit count to main branch (e.g., "42")
    static let buildNumber = "0"

    /// Environment (development, staging, or production)
    static let environment = "development"
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
