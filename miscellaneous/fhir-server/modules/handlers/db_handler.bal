import ballerina_fhir_server.utils;

import ballerina/io;
import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

// Database connection configuration
configurable string dbUrl      = "jdbc:h2:./db/BAL_FHIR_DB";
configurable string dbUser     = "sa";
configurable string dbPassword = "";
public configurable string dbType       = "h2";

// Connection pool
configurable int dbPoolMaxSize = 50;
configurable int dbPoolMinIdle = 10;

public class DBHandler {
    private final DatabaseProvider databaseProvider;
    private jdbc:Client|sql:Error jdbcClient;

    private sql:ParameterizedQuery[] createQueries;
    private final int CURRENT_SCHEMA_VERSION = 3;

    public function init() returns error? {
        DatabaseProvider|error provider = getDatabaseProvider(dbType);
        if provider is error {
            log:printError(string `Failed to initialize database provider: ${provider.message()}`);
            return provider;
        }
        self.databaseProvider = provider;
        setActiveDatabaseProvider(provider);

        sql:ConnectionPool connectionPool = {
            maxOpenConnections: dbPoolMaxSize,
            minIdleConnections: dbPoolMinIdle
        };
        self.jdbcClient = new (dbUrl, dbUser, dbPassword, connectionPool = connectionPool);
        self.createQueries = [];
    }

    public function initializeJdbcClient() returns jdbc:Client|sql:Error {
        return self.jdbcClient;
    }

    public function initDatabase(jdbc:Client jdbcClient) returns error? {
        log:printInfo("Initializing database...");

        boolean|error dbExists = self.databaseProvider.isDatabaseExists(jdbcClient);
        if dbExists is error {
            log:printError("Failed to check database state: " + dbExists.message());
            return dbExists;
        }

        if dbExists {
            log:printInfo("Tables exist. Checking schema version...");
            int|error version = jdbcClient->queryRow(self.databaseProvider.getSchemaVersionQuery());
            if version is int && version >= self.CURRENT_SCHEMA_VERSION {
                log:printInfo(string `Schema up to date (v${version}).`);
                check self.populateSearchParamDefsIfEmpty(jdbcClient);
                return;
            }
            log:printInfo(string `Schema outdated or unknown. Running initialisation...`);
        } else {
            log:printInfo(string `No tables found. Creating schema (${self.databaseProvider.getDatabaseType()})...`);
        }

        if self.databaseProvider.getDatabaseType().toLowerAscii().trim() == "h2" {
            check self.retreiveQueriesFromSchema();
            foreach sql:ParameterizedQuery q in self.createQueries {
                sql:ExecutionResult|sql:Error r = jdbcClient->execute(q);
                if r is sql:Error {
                    log:printDebug("Schema DDL (may already exist): " + r.message());
                }
            }
            _ = check jdbcClient->execute(`DELETE FROM "schema_version"`);
            _ = check jdbcClient->execute(`INSERT INTO "schema_version" ("version") VALUES (${self.CURRENT_SCHEMA_VERSION})`);
            log:printInfo(string `H2 schema initialised at v${self.CURRENT_SCHEMA_VERSION}.`);
        } else {
            log:printInfo("PostgreSQL: schema must be applied externally via scripts/schema-postgresql.sql");
        }

        check self.populateSearchParamDefs(jdbcClient);
        log:printInfo("Database ready.");
    }

    // ─── Schema DDL loading (H2 only) ─────────────────────────────────────────

    private function convertToParameterizedQuery(readonly & string[] strQuery) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery q = ``;
        q.strings = strQuery;
        return q;
    }

    private function retreiveQueriesFromSchema() returns error? {
        final string:RegExp lineSep = re `\n`;
        string[] lines = lineSep.split(H2_SCHEMA_SQL);
        boolean inBlock = false;
        string current  = "";

        foreach string line in lines {
            string t = string:trim(line);
            if t == "" || t.startsWith("DROP") || t.startsWith("--") { continue; }

            if t.startsWith("CREATE") || t.startsWith("INSERT") {
                inBlock  = true;
                current  = t;
            } else if inBlock {
                current += " " + t;
            }

            if inBlock && t.endsWith(";") {
                readonly & string[] arr = [current].cloneReadOnly();
                self.createQueries.push(self.convertToParameterizedQuery(arr));
                inBlock = false;
                current = "";
            }
        }
    }

    // ─── Search param definitions population ──────────────────────────────────

    private function populateSearchParamDefsIfEmpty(jdbc:Client jdbcClient) returns error? {
        int count = check jdbcClient->queryRow(`SELECT COUNT(*) AS count FROM search_param_definitions`);
        if count > 0 {
            log:printInfo(string `search_param_definitions: ${count} rows already present.`);
            return;
        }
        return self.populateSearchParamDefs(jdbcClient);
    }

    private function populateSearchParamDefs(jdbc:Client jdbcClient) returns error? {
        final string csvPath = "./assets/r4-searchParam-Expression.csv";
        string[] lines;
        string[]|error fileLines = io:fileReadLines(csvPath);
        if fileLines is error {
            log:printDebug("CSV not found on disk, using embedded data: " + fileLines.message());
            lines = re`\n`.split(SEARCH_PARAM_EXPRESSIONS_CSV);
        } else {
            lines = fileLines;
        }

        int inserted = 0;
        final string:RegExp comma = re `,`;

        foreach int i in 1 ..< lines.length() {
            string line = lines[i];
            string[] cols = comma.split(line);
            if cols.length() != 4 { continue; }

            string paramName  = cols[0].trim();
            string resource   = cols[1].trim();
            string paramType  = cols[2].trim();
            string expression = cols[3].trim();

            if paramName.length() == 0 { continue; }

            // Upsert — ON CONFLICT DO NOTHING keeps existing custom params untouched
            sql:ParameterizedQuery q;
            string normalizedDbType = dbType.toLowerAscii().trim();
            if normalizedDbType == "postgresql" || normalizedDbType == "postgres" {
                q = `INSERT INTO search_param_definitions (resource_type, param_name, param_type, fhirpath_expr, is_custom)
                     VALUES (${resource}, ${paramName}, ${paramType}, ${expression}, FALSE)
                     ON CONFLICT (resource_type, param_name) DO NOTHING`;
            } else {
                // H2: MERGE to achieve upsert semantics
                q = `MERGE INTO "search_param_definitions" ("resource_type", "param_name", "param_type", "fhirpath_expr", "is_custom")
                     KEY ("resource_type", "param_name")
                     VALUES (${resource}, ${paramName}, ${paramType}, ${expression}, FALSE)`;
            }
            sql:ExecutionResult|sql:Error r = jdbcClient->execute(q);
            if r is sql:Error {
                log:printDebug(string `search_param_definitions insert failed for ${resource}.${paramName}: ${r.message()}`);
            } else {
                inserted += 1;
            }
        }
        log:printInfo(string `Populated search_param_definitions with ${inserted} definitions.`);
    }
}
