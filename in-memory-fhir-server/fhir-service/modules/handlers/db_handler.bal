import ballerina_fhir_server.db_store;

import ballerina/io;
import ballerina/sql;
import ballerinax/java.jdbc;

public class DBHandler {
    private final string filePath = "./modules/db_store/script.sql";
    private final jdbc:Client|sql:Error jdbcClient = new ("jdbc:h2:~./fhir-data-db", "sa", "");

    private sql:ParameterizedQuery[] dropQueries;
    private sql:ParameterizedQuery[] createQueries;

    public function init() {
        self.dropQueries = [];
        self.createQueries = [];
    }

    public function initializeJdbcClient() returns jdbc:Client|sql:Error {
        return self.jdbcClient;
    }

    public function initializePersistClient() returns db_store:Client|error {
        return new ();
    }

    private function isDBExsists(jdbc:Client jdbcClient) returns boolean|error {
        sql:ParameterizedQuery query = `SELECT COUNT(TABLE_CATALOG) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='PUBLIC'`;
        int count = check jdbcClient->queryRow(query);
        if (count == 135) {
            return true;
        }
        return false;
    }

    public function initDatabase(jdbc:Client jdbcClient, db_store:Client persistClient) returns boolean|error? {
        if (self.isDBExsists(jdbcClient) is error) {
            return false;
        } else if (self.isDBExsists(jdbcClient) == true) {
            return true;
        } else {
            sql:ExecutionResult dropQueryResult = {affectedRowCount: 0, lastInsertId: 0};
            sql:ExecutionResult createQueryResult = {affectedRowCount: 0, lastInsertId: 0};

            error? isError = self.retreiveQueriesFromSchema();

            if (isError is error) {
                io:println("An error occured when reading the db schema: " + isError.message());
                return false;
            } else {
                foreach sql:ParameterizedQuery dropQuery in self.dropQueries {
                    sql:ParameterizedQuery query1 = dropQuery;
                    dropQueryResult = check jdbcClient->execute(query1);
                }

                foreach sql:ParameterizedQuery createQuery in self.createQueries {
                    sql:ParameterizedQuery query2 = createQuery;
                    createQueryResult = check jdbcClient->execute(query2);
                }
            }

            io:println("Drop Query Result: " + dropQueryResult.toString());
            io:println("Create Query Result: " + createQueryResult.toString());

            // MIGHT BE OBSOLETE: Check whether if necessary
            error? isSearchParamsPopulated = self.populateSearchParamExpressionTable(persistClient);
            if (isSearchParamsPopulated is error) {
                io:print("An error occured while populating the SEARCH_PARAM_EXPRESSION_TABLE: " + isSearchParamsPopulated.message());
                return false;
            } else {
                io:println("SEARCH_PARAM_EXPRESSION TABLE populated successfully!");
                return true;
            }
        }
    }

    private function convertToParameterizedQuery(readonly & string[] strQuery) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery parameterizedQuery = ``;
        parameterizedQuery.strings = strQuery;
        return parameterizedQuery;
    }

    private function retreiveQueriesFromSchema() returns error? {
        string[] readLines = check io:fileReadLines(self.filePath);

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

    private function populateSearchParamExpressionTable(db_store:Client persistClient) returns error? {
        final string dataFilePath = "./assets/r4-searchParam-Expression.csv";
        final string[] readLines = check io:fileReadLines(dataFilePath);
        final string:RegExp regex = re `,`;
        int i = 0;
        int totRecords = 0;

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

                db_store:SEARCH_PARAM_RES_EXPRESSIONSInsert searchParamResourceExpression = {
                    SEARCH_PARAM_NAME: searchParamName,
                    SEARCH_PARAM_TYPE: searchParamType,
                    RESOURCE_NAME: 'resource,
                    EXPRESSION: expression
                };

                int[] recordId = check persistClient->/search_param_res_expressions.post([searchParamResourceExpression]);
                totRecords = recordId[0]; // tot_records = last_rec_id
            }
        }
        io:println("Total Records Inserted: " + totRecords.toString());
    }
}
