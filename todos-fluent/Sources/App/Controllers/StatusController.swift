import Foundation
import Hummingbird

struct StatusController<Repository: TodoRepository> {
    // Todo repository for database health check
    let repository: Repository

    // return status endpoints
    var endpoints: RouteCollection<AppRequestContext> {
        return RouteCollection(context: AppRequestContext.self)
            .get("/health", use: self.health)
            .get("/version", use: self.version)
    }

    /// Health check response
    struct HealthResponse: ResponseCodable {
        let status: String
        let databaseConnected: Bool
    }

    /// Health check entrypoint - verifies database connectivity
    @Sendable func health(request: Request, context: some RequestContext) async throws -> HealthResponse {
        // Try to query the database to verify connectivity
        do {
            _ = try await self.repository.list()
            return HealthResponse(status: "ok", databaseConnected: true)
        } catch {
            // If database query fails, return unhealthy status
            throw HTTPError(.serviceUnavailable, message: "Database connection failed")
        }
    }

    /// Version information entrypoint
    @Sendable func version(request: Request, context: some RequestContext) async throws -> AppVersionResponse {
        return AppVersionResponse(
            version: AppVersion.version,
            buildNumber: AppVersion.buildNumber,
            environment: AppVersion.environment
        )
    }
}
