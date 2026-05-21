import ballerina/sql;
import ballerinax/java.jdbc;

public class PostgreSQLDatabaseProvider {
    *DatabaseProvider;

    private final string schemaPath = "./scripts/schema-postgresql.sql";
    private final string dbType = "postgresql";

    public function init() {
    }

    public function isDatabaseExists(jdbc:Client jdbcClient) returns boolean|error {
        sql:ParameterizedQuery query = `SELECT COUNT(*)
                                        FROM information_schema.tables
                                        WHERE table_schema='public'`;
        int count = check jdbcClient->queryRow(query);
        return count > 0;
    }

    public function getSchemaFilePath() returns string {
        return self.schemaPath;
    }

    public function getTableColumnsQuery(string tableName) returns sql:ParameterizedQuery {
        return `SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = ${tableName}
                ORDER BY ordinal_position`;
    }

    public function getSchemaVersionQuery() returns sql:ParameterizedQuery {
        return `SELECT version FROM schema_version ORDER BY version DESC LIMIT 1`;
    }

    public function getDatabaseType() returns string {
        return self.dbType;
    }
}
