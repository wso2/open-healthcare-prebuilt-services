import ballerina/sql;
import ballerinax/java.jdbc;

# Database provider interface that defines database-specific operations.
public type DatabaseProvider object {

    public function isDatabaseExists(jdbc:Client jdbcClient) returns boolean|error;

    public function getSchemaFilePath() returns string;

    public function getTableColumnsQuery(string tableName) returns sql:ParameterizedQuery;

    public function getSchemaVersionQuery() returns sql:ParameterizedQuery;

    public function getDatabaseType() returns string;
};
