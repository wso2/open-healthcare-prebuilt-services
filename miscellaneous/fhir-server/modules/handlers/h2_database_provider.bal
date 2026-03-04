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

# H2 Database provider implementation.
# Contains H2-specific SQL queries and operations.
public class H2DatabaseProvider {
    *DatabaseProvider;

    private final string schemaPath = "./scripts/schema-h2.sql";
    private final string dbType = "h2";

    public function init() {
    }

    # Check if H2 database schema exists by querying INFORMATION_SCHEMA.
    #
    # + jdbcClient - JDBC client connection
    # + return - True if tables exist in PUBLIC schema, false otherwise, or error
    public function isDatabaseExists(jdbc:Client jdbcClient) returns boolean|error {
        // H2-specific query: Check for tables in PUBLIC schema
        sql:ParameterizedQuery query = `SELECT COUNT(TABLE_CATALOG) 
                                        FROM INFORMATION_SCHEMA.TABLES 
                                        WHERE TABLE_SCHEMA='PUBLIC'`;
        int count = check jdbcClient->queryRow(query);
        return count > 0;
    }

    # Get the path to H2-specific schema file.
    #
    # + return - Path to schema-h2.sql file
    public function getSchemaFilePath() returns string {
        return self.schemaPath;
    }

    # Get H2-specific query to retrieve table column names.
    # Uses INFORMATION_SCHEMA with uppercase PUBLIC schema.
    #
    # + tableName - Name of the table
    # + return - Parameterized query for H2
    public function getTableColumnsQuery(string tableName) returns sql:ParameterizedQuery {
        return `SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = 'PUBLIC' 
                  AND TABLE_NAME = ${tableName}
                ORDER BY ORDINAL_POSITION`;
    }

    # Get database type identifier.
    #
    # + return - "h2"
    public function getDatabaseType() returns string {
        return self.dbType;
    }
}
