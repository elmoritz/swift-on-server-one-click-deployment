// AppVersion.swift
// This file contains hardcoded version information
// It is automatically generated during the build process

enum AppVersion {
    // MARK: - Version Information
    // These values are set by the CI/CD pipeline during build

    /// Current application version
    /// Format: MAJOR.MINOR.PATCH.BUILD for staging (e.g., 0.1.0.42)
    /// Format: MAJOR.MINOR.PATCH for production (e.g., 1.2.3)
    static let current = "0.0.0.0-dev"

    /// Build date in ISO8601 format
    static let buildDate = "1970-01-01T00:00:00Z"

    /// Environment (staging or production)
    static let environment = "development"
}
