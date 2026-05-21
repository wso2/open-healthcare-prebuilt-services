import ballerina/sql;
import ballerinax/java.jdbc;

public class H2DatabaseProvider {
    *DatabaseProvider;

    private final string schemaPath = "./scripts/schema-h2.sql";
    private final string dbType = "h2";

    public function init() {
    }

    public function isDatabaseExists(jdbc:Client jdbcClient) returns boolean|error {
        sql:ParameterizedQuery query = `SELECT COUNT(TABLE_CATALOG)
                                        FROM INFORMATION_SCHEMA.TABLES
                                        WHERE TABLE_SCHEMA='PUBLIC'`;
        int count = check jdbcClient->queryRow(query);
        return count > 0;
    }

    public function getSchemaFilePath() returns string {
        return self.schemaPath;
    }

    public function getTableColumnsQuery(string tableName) returns sql:ParameterizedQuery {
        return `SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = 'PUBLIC'
                  AND TABLE_NAME = ${tableName}
                ORDER BY ORDINAL_POSITION`;
    }

    public function getSchemaVersionQuery() returns sql:ParameterizedQuery {
        return `SELECT "version" FROM "schema_version" ORDER BY "version" DESC LIMIT 1`;
    }

    public function getDatabaseType() returns string {
        return self.dbType;
    }
}
