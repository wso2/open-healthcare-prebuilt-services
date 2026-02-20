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
configurable boolean clearDataOnStartup = false;

// Connection pool settings
configurable int dbPoolMaxSize = 50;     // max open connections
configurable int dbPoolMinIdle = 10;     // idle connections kept warm

public class DBHandler {
    private final DatabaseProvider databaseProvider;
    private jdbc:Client|sql:Error jdbcClient;

    private sql:ParameterizedQuery[] dropQueries;
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
        
        self.dropQueries = [];
        self.createQueries = [];
    }

    public function initializeJdbcClient() returns jdbc:Client|sql:Error {
        return self.jdbcClient;
    }

    private function isDBExsists(jdbc:Client jdbcClient) returns boolean|error {
        return self.databaseProvider.isDatabaseExists(jdbcClient);
    }

    public function initDatabase(jdbc:Client jdbcClient) returns boolean|error? {
        boolean|error dbExists = self.isDBExsists(jdbcClient);
        
        if (dbExists is error) {
            return false;
        } else if (dbExists == true) {
            // Database exists - check if we should clear it
            if (clearDataOnStartup) {
                log:printWarn("Clearing existing database data as clearDataOnStartup is enabled...");
                // Truncate all tables instead of dropping and recreating
                error? truncateResult = self.truncateAllTables(jdbcClient);
                if (truncateResult is error) {
                    log:printError("An error occurred while truncating tables: " + truncateResult.message());
                    return false;
                }
                
                // Populate search parameters after truncating
                error? isSearchParamsPopulated = self.populateSearchParamExpressionTable(jdbcClient);
                if (isSearchParamsPopulated is error) {
                    log:printError("An error occurred while populating SEARCH_PARAM_RES_EXPRESSIONS: " + isSearchParamsPopulated.message());
                    return false;
                } else {
                    log:printInfo("Database cleared and SEARCH_PARAM_RES_EXPRESSIONS table populated successfully!");
                    return true;
                }
            } else {
                log:printInfo("Database already exists. Skipping table creation to preserve existing data.");
                
                // For PostgreSQL, populate search params if table is empty
                if (self.databaseProvider.getDatabaseType() == "postgresql") {
                    error? isSearchParamsPopulated = self.populateSearchParamExpressionTableIfEmpty(jdbcClient);
                    if (isSearchParamsPopulated is error) {
                        log:printError("An error occurred while populating SEARCH_PARAM_RES_EXPRESSIONS: " + isSearchParamsPopulated.message());
                        return false;
                    }
                }
                return true;
            }
        }
        
        // Initialize database for first time (H2 only - creates tables)
        error? isError = self.retreiveQueriesFromSchema();

        if (isError is error) {
            log:printError("An error occured when reading the db schema: " + isError.message());
            return false;
        } else {
            foreach sql:ParameterizedQuery dropQuery in self.dropQueries {
                sql:ParameterizedQuery query1 = dropQuery;
                _ = check jdbcClient->execute(query1);
            }

            foreach sql:ParameterizedQuery createQuery in self.createQueries {
                sql:ParameterizedQuery query2 = createQuery;
                _ = check jdbcClient->execute(query2);
            }
        }

        // Populate search parameters for H2 first-time initialization
        error? isSearchParamsPopulated = self.populateSearchParamExpressionTable(jdbcClient);
        if (isSearchParamsPopulated is error) {
            log:printError("An error occured while populating the SEARCH_PARAM_EXPRESSION_TABLE: " + isSearchParamsPopulated.message());
            return false;
        } else {
            log:printDebug("SEARCH_PARAM_EXPRESSION TABLE populated successfully!");
            return true;
        }
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

            // Handle DROP queries
            if trimmed.startsWith("DROP") && trimmed.endsWith(";") {
                readonly & string[] tempArr = [trimmed];
                self.dropQueries.push(self.convertToParameterizedQuery(tempArr));
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

    private function truncateAllTables(jdbc:Client jdbcClient) returns error? {
        log:printInfo("Truncating all tables...");
        
        // Get list of tables from schema
        string schemaFilePath = self.databaseProvider.getSchemaFilePath();
        string[] readLines = check io:fileReadLines(schemaFilePath);
        
        string[] tableNames = [];
        
        // Extract table names from CREATE TABLE statements
        foreach string line in readLines {
            string trimmed = string:trim(line);
            if trimmed.startsWith("CREATE TABLE") {
                // Extract table name between quotes
                int? firstQuote = trimmed.indexOf("\"");
                if firstQuote is int {
                    int? secondQuote = trimmed.indexOf("\"", firstQuote + 1);
                    if secondQuote is int {
                        string tableName = trimmed.substring(firstQuote + 1, secondQuote);
                        tableNames.push(tableName);
                    }
                }
            }
        }
        
        log:printInfo(string `Found ${tableNames.length()} tables to truncate`);
        
        // Truncate tables in reverse order to handle foreign key constraints
        int i = tableNames.length();
        while (i > 0) {
            i -= 1;
            string tableName = tableNames[i];
            
            // Use TRUNCATE with CASCADE for PostgreSQL, or DELETE for H2
            string dbType = self.databaseProvider.getDatabaseType();
            string truncateQuery = "";
            
            if (dbType == "postgresql") {
                truncateQuery = string `TRUNCATE TABLE "${tableName}" CASCADE`;
            } else {
                // H2 doesn't support TRUNCATE CASCADE, use DELETE
                truncateQuery = string `DELETE FROM "${tableName}"`;
            }
            
            sql:ParameterizedQuery query = new utils:RawSQLQuery(truncateQuery);
            _ = check jdbcClient->execute(query);
            log:printDebug(string `Truncated table: ${tableName}`);
        }
        
        log:printInfo("All tables truncated successfully");
        return ();
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
