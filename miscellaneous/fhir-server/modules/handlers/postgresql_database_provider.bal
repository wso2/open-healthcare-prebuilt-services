// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/sql;
import ballerinax/java.jdbc;

# PostgreSQL Database provider implementation.
# Contains PostgreSQL-specific SQL queries and operations.
public class PostgreSQLDatabaseProvider {
    *DatabaseProvider;

    private final string schemaPath = "./scripts/schema-postgresql.sql";
    private final string dbType = "postgresql";

    public function init() {
    }

    # Check if PostgreSQL database schema exists by querying information_schema.
    #
    # + jdbcClient - JDBC client connection
    # + return - True if tables exist in public schema, false otherwise, or error
    public function isDatabaseExists(jdbc:Client jdbcClient) returns boolean|error {
        // PostgreSQL-specific query: Check for tables in public schema (lowercase)
        sql:ParameterizedQuery query = `SELECT COUNT(*) 
                                        FROM information_schema.tables 
                                        WHERE table_schema='public'`;
        int count = check jdbcClient->queryRow(query);
        return count > 0;
    }

    # Get the path to PostgreSQL-specific schema file.
    #
    # + return - Path to schema-postgresql.sql file
    public function getSchemaFilePath() returns string {
        return self.schemaPath;
    }

    # Get PostgreSQL-specific query to retrieve table column names.
    # Uses information_schema with lowercase public schema.
    #
    # + tableName - Name of the table
    # + return - Parameterized query for PostgreSQL
    public function getTableColumnsQuery(string tableName) returns sql:ParameterizedQuery {
        return `SELECT column_name 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                  AND table_name = ${tableName}
                ORDER BY ordinal_position`;
    }

    # Get database type identifier.
    #
    # + return - "postgresql"
    public function getDatabaseType() returns string {
        return self.dbType;
    }
}
