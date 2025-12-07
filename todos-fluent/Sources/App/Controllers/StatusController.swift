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

        // Verify database connectivity by attempting a transaction
        // This tests actual database connectivity without depending on any models
        do {
            try await db.transaction { transaction in
                // Empty transaction - just verifies we can connect to the database
                transaction.eventLoop.makeSucceededFuture(())
            }.get()
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
        var environment: String
    }

    /// Version endpoint - returns the hardcoded application version
    @Sendable func version(_ request: Request, context: Context) async throws -> VersionResponse {
        // Version is hardcoded and set during build process
        let versionString = AppVersion.current
        let buildDate = AppVersion.buildDate
        let environment = AppVersion.environment

        return VersionResponse(
            version: versionString,
            buildDate: buildDate,
            environment: environment
        )
    }
}

