import Hummingbird
import Logging
import FluentPostgresDriver
import HummingbirdFluent

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
    var inMemoryTesting: Bool { get }
}

enum StartUpError: Error {
    case databaseCouldNotBeCreated
}


// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "todos-postgres-tutorial")
        logger.logLevel =
            arguments.logLevel ??
            environment.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ?? .info
        return logger
    }()

    var fluent: Fluent?
    let router: Router<AppRequestContext>
    if !arguments.inMemoryTesting {
        let fluentNonOptional = Fluent(logger: logger)
        let postgresConfig: DatabaseConfigurationFactory = .postgres(
            configuration: getPostgresConfig(arguments: arguments)
        )
        fluentNonOptional.databases.use(postgresConfig, as: .psql)

        guard let db = fluentNonOptional.databases.database(logger: logger, on: fluentNonOptional.eventLoopGroup.any()) else {
            throw StartUpError.databaseCouldNotBeCreated
        }

        await fluentNonOptional.migrations.add(CreateTodoModel())

        fluent = fluentNonOptional
        let repository = TodoPostgresRepository(db: db)
        router = buildRouter(repository)
    } else {
        router = buildRouter(TodoMemoryRepository())
    }
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "todos-postgres-tutorial"
        ),
        logger: logger
    )
    // if we setup a postgres service then add as a service and run createTable before
    // server starts
    if let fluent {
        app.addServices(fluent)
        app.beforeServerStarts {
            try await fluent.migrate()
        }
    }
    return app
}

func getPostgresConfig(arguments: some AppArguments) -> SQLPostgresConfiguration {
    let environment = Environment()
    return .init(
        hostname: environment.get("POSTGRES_HOST") ?? "localhost",
        port: Int(environment.get("POSTGRES_PORT") ?? "5432") ?? 5432,
        username: environment.get("POSTGRES_USER") ?? "postgres",
        password: environment.get("POSTGRES_PASSWORD") ?? "TopSecretPassword",
        database: environment.get("POSTGRES_DB") ?? "postgres",
        tls: .disable
    )
}

/// Build router
func buildRouter(_ repository: some TodoRepository) -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    // Add status endpoints (health and version)
    router.addRoutes(StatusController(repository: repository).endpoints)
    // Add todo endpoints
    router.addRoutes(TodoController(repository: repository).endpoints, atPath: "/todos")
    return router
}
