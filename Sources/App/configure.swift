import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.http.server.configuration.port = 9090
//    app.http.server.configuration.hostname = "10.10.57.130"
    app.middleware.use(CORSMiddleware())
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
    app.databases.use(.postgres(hostname: "127.0.0.1",
                                username: "postgres",
                                password: "1990823",
                                database: "realm_log"),
                          as: .psql)

    app.migrations.add(CreateNetworkLogMigrations())
    
    try app.autoMigrate().wait()
    
    
    // register routes
    try routes(app)
}
