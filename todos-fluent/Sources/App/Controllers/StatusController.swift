//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2021 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import FluentKit
import Foundation
import Hummingbird
import HummingbirdFluent
import NIO

struct StatusController<Context: RequestContext> {
    let fluent: Fluent

    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get("health", use: self.health)
            .get("version", use: self.version)
    }

    struct HealthResponse: ResponseCodable {
        var status: String
        var database: DatabaseHealth
        var timestamp: String

        struct DatabaseHealth: Codable {
            var connected: Bool
            var message: String
        }
    }

    /// Health check endpoint - checks database connectivity and returns service status
    @Sendable func health(_ request: Request, context: Context) async throws -> HealthResponse {
        let db = self.fluent.db()
        var databaseHealth = HealthResponse.DatabaseHealth(connected: false, message: "Not checked")

        // Try a simple query to verify database connectivity
        do {
            _ = try await db.raw("SELECT 1").all()
            databaseHealth = HealthResponse.DatabaseHealth(connected: true, message: "Connected")
        } catch {
            databaseHealth = HealthResponse.DatabaseHealth(connected: false, message: "Connection failed: \(error.localizedDescription)")
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let overallStatus = databaseHealth.connected ? "healthy" : "unhealthy"

        return HealthResponse(
            status: overallStatus,
            database: databaseHealth,
            timestamp: timestamp
        )
    }

    struct VersionResponse: ResponseCodable {
        var version: String
        var buildDate: String
    }

    /// Version endpoint - returns the application version from VERSION file
    @Sendable func version(_ request: Request, context: Context) async throws -> VersionResponse {
        // Read version from VERSION file (single source of truth)
        let versionString = try await Self.readVersion()
        let buildDate = ISO8601DateFormatter().string(from: Date())

        return VersionResponse(
            version: versionString,
            buildDate: buildDate
        )
    }

    /// Read version string from VERSION file
    private static func readVersion() async throws -> String {
        // Try multiple possible locations for the VERSION file
        let possiblePaths = [
            "../../../VERSION",  // When running from build directory
            "VERSION",           // When running from project root
            "../../VERSION"      // Alternative build location
        ]

        for path in possiblePaths {
            if let version = try? String(contentsOfFile: path, encoding: .utf8) {
                return version.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Fallback: try to read from embedded resource if available
        throw HTTPError(.internalServerError, message: "VERSION file not found")
    }
}
