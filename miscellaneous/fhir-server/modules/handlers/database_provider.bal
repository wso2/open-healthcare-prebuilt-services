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

# Database provider interface that defines database-specific operations.
# Different database implementations (H2, PostgreSQL, MySQL, etc.) should implement this interface.
public type DatabaseProvider object {

    # Check if the database schema exists.
    #
    # + jdbcClient - JDBC client connection
    # + return - True if database exists, false otherwise, or error
    public function isDatabaseExists(jdbc:Client jdbcClient) returns boolean|error;

    # Get the path to the database-specific schema file.
    #
    # + return - File path to the SQL schema file
    public function getSchemaFilePath() returns string;

    # Get the database-specific query to retrieve table columns.
    #
    # + tableName - Name of the table
    # + return - Parameterized SQL query
    public function getTableColumnsQuery(string tableName) returns sql:ParameterizedQuery;

    # Get the database type identifier.
    #
    # + return - Database type name (e.g., "h2", "postgresql")
    public function getDatabaseType() returns string;
};
