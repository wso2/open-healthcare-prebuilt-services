import ballerina_fhir_server.utils;

import ballerina/io;
import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;

// Database configuration
configurable string dbUrl = "jdbc:h2:./db/BAL_FHIR_DB";
configurable string dbUser = "sa";
configurable string dbPassword = "";
public configurable string dbType = "h2"; // Default to H2 for backward compatibility

// Connection pool settings
configurable int dbPoolMaxSize = 50;     // max open connections
configurable int dbPoolMinIdle = 10;     // idle connections kept warm

public class DBHandler {
    private final DatabaseProvider databaseProvider;
    private jdbc:Client|sql:Error jdbcClient;

    private sql:ParameterizedQuery[] createQueries;

    public function init() returns error? {
        // Initialize the appropriate database provider
        DatabaseProvider|error provider = getDatabaseProvider(dbType);
        if provider is error {
            log:printError(string `Failed to initialize database provider: ${provider.message()}`);
            return provider;
        }
        self.databaseProvider = provider;

        // Set the active database provider for global access (used by utils)
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

    private function isDBExsists(jdbc:Client jdbcClient) returns boolean|error {
        return self.databaseProvider.isDatabaseExists(jdbcClient);
    }

    public function initDatabase(jdbc:Client jdbcClient) returns error? {
        boolean|error dbExists = self.isDBExsists(jdbcClient);

        if dbExists is error {
            log:printError("Failed to check database state: " + dbExists.message());
            return dbExists;
        }

        if dbExists {
            log:printInfo("Database tables already exist. Starting server with existing data.");

            error? isSearchParamsPopulated = self.populateSearchParamExpressionTableIfEmpty(jdbcClient);
            if isSearchParamsPopulated is error {
                log:printError("Failed to populate SEARCH_PARAM_RES_EXPRESSIONS: " + isSearchParamsPopulated.message());
                return isSearchParamsPopulated;
            }
            return;
        }

        log:printInfo(string `No existing tables found. Creating database schema for the first time (${self.databaseProvider.getDatabaseType()})...`);

        error? schemaError = self.retreiveQueriesFromSchema();
        if schemaError is error {
            log:printError("Failed to read database schema file: " + schemaError.message());
            return schemaError;
        }

        foreach sql:ParameterizedQuery createQuery in self.createQueries {
            sql:ParameterizedQuery query = createQuery;
            sql:ExecutionResult|sql:Error execResult = jdbcClient->execute(query);
            if execResult is sql:Error {
                log:printError("Failed to create database tables: " + execResult.message());
                return execResult;
            }
        }

        error? isSearchParamsPopulated = self.populateSearchParamExpressionTable(jdbcClient);
        if isSearchParamsPopulated is error {
            log:printError("Failed to populate SEARCH_PARAM_RES_EXPRESSIONS: " + isSearchParamsPopulated.message());
            return isSearchParamsPopulated;
        }

        log:printInfo("Database schema created and initialized successfully.");
    }

    private function convertToParameterizedQuery(readonly & string[] strQuery) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery parameterizedQuery = ``;
        parameterizedQuery.strings = strQuery;
        return parameterizedQuery;
    }

    private function retreiveQueriesFromSchema() returns error? {
        string schemaFilePath = self.databaseProvider.getSchemaFilePath();
        string[] readLines = check io:fileReadLines(schemaFilePath);

        boolean inCreateQuery = false;
        string currentCreateQuery = "";

        foreach string line in readLines {
            string trimmed = string:trim(line);

            if trimmed == "" {
                continue;
            }
            if trimmed.startsWith("DROP") {
                continue;
            }

            // Handle CREATE queries
            if trimmed.startsWith("CREATE") {
                inCreateQuery = true;
                currentCreateQuery = trimmed;

                // If CREATE ends immediately with `;`
                if trimmed.endsWith(";") {
                    readonly & string[] tempArr = [currentCreateQuery];
                    self.createQueries.push(self.convertToParameterizedQuery(tempArr));
                    inCreateQuery = false;
                    currentCreateQuery = "";
                }
                continue;
            }

            if inCreateQuery {
                currentCreateQuery = currentCreateQuery + " " + trimmed;

                if trimmed.endsWith(";") {
                    readonly & string[] tempArr = [currentCreateQuery];
                    self.createQueries.push(self.convertToParameterizedQuery(tempArr));
                    inCreateQuery = false;
                    currentCreateQuery = "";
                }
            }
        }
    }

    private function populateSearchParamExpressionTableIfEmpty(jdbc:Client jdbcClient) returns error? {
        // Check if table is empty
        sql:ParameterizedQuery countQuery = `SELECT COUNT(*) as count FROM "SEARCH_PARAM_RES_EXPRESSIONS"`;
        int count = check jdbcClient->queryRow(countQuery);
        
        if (count > 0) {
            log:printInfo(string `SEARCH_PARAM_RES_EXPRESSIONS table already has ${count} records. Skipping population.`);
            return ();
        }
        
        log:printInfo("SEARCH_PARAM_RES_EXPRESSIONS table is empty. Populating from CSV...");
        return self.populateSearchParamExpressionTable(jdbcClient);
    }

    private function populateSearchParamExpressionTable(jdbc:Client jdbcClient) returns error? {
        final string dataFilePath = "./assets/r4-searchParam-Expression.csv";
        final string[] readLines = check io:fileReadLines(dataFilePath);
        final string:RegExp regex = re `,`;
        int i = 0;

        foreach string line in readLines {
            i += 1;

            // Exclude Header
            if (i == 1) {
                continue;
            }

            string[] data = regex.split(line);

            if (data.length() == 4) {
                string searchParamName = data[0];
                string 'resource = data[1];
                string searchParamType = data[2];
                string expression = data[3];

                string sqlQuery = string `INSERT INTO "SEARCH_PARAM_RES_EXPRESSIONS" ("SEARCH_PARAM_NAME", "SEARCH_PARAM_TYPE", "RESOURCE_NAME", "EXPRESSION") VALUES ('${utils:escapeSql(searchParamName)}', '${utils:escapeSql(searchParamType)}', '${utils:escapeSql('resource)}', '${utils:escapeSql(expression)}')`;
                sql:ParameterizedQuery query = new utils:RawSQLQuery(sqlQuery);

                _ = check jdbcClient->execute(query);
            }
        }
        log:printInfo(string `Populated SEARCH_PARAM_RES_EXPRESSIONS table with ${i - 1} records from CSV`);
    }
}
