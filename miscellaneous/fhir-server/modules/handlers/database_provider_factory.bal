import ballerina/log;

public enum DatabaseType {
    H2 = "h2",
    POSTGRESQL = "postgresql"
}

DatabaseProvider? activeDatabaseProvider = ();

public function getDatabaseProvider(string dbType) returns DatabaseProvider|error {
    string normalizedType = dbType.toLowerAscii().trim();
    match normalizedType {
        "h2" => {
            log:printInfo("Initializing H2 database provider");
            return new H2DatabaseProvider();
        }
        "postgresql" | "postgres" => {
            log:printInfo("Initializing PostgreSQL database provider");
            return new PostgreSQLDatabaseProvider();
        }
        _ => {
            string errorMsg = string `Unsupported database type: ${dbType}. Supported types are: h2, postgresql`;
            log:printError(errorMsg);
            return error(errorMsg);
        }
    }
}

public function setActiveDatabaseProvider(DatabaseProvider provider) {
    lock {
        activeDatabaseProvider = provider;
    }
}

public function getActiveDatabaseProvider() returns DatabaseProvider|error {
    lock {
        DatabaseProvider? provider = activeDatabaseProvider;
        if provider is () {
            return error("Database provider not initialized. Call setActiveDatabaseProvider first.");
        }
        return provider;
    }
}

public isolated function isSupportedDatabaseType(string dbType) returns boolean {
    string normalizedType = dbType.toLowerAscii().trim();
    return normalizedType == "h2" || normalizedType == "postgresql" || normalizedType == "postgres";
}

public isolated function getSupportedDatabaseTypes() returns string[] {
    return ["h2", "postgresql"];
}
