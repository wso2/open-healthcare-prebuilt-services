// Copyright (c) 2025, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;

# Database provider factory for creating appropriate database provider instances
# based on the database type configuration.

# Supported database types
public enum DatabaseType {
    H2 = "h2",
    POSTGRESQL = "postgresql"
}

// Singleton instance for the active database provider
DatabaseProvider? activeDatabaseProvider = ();

# Creates and returns the appropriate database provider based on the database type.
#
# + dbType - The database type (h2, postgresql, etc.)
# + return - DatabaseProvider instance or error if unsupported database type
public function getDatabaseProvider(string dbType) returns DatabaseProvider|error {
    string normalizedType = dbType.toLowerAscii().trim();
    
    match normalizedType {
        "h2" => {
            log:printInfo("Initializing H2 database provider");
            return new H2DatabaseProvider();
        }
        "postgresql" | "postgres" => {
            log:printInfo("Initializing PostgreSQL database provider");
            return new PostgreSQLDatabaseProvider();
        }
        _ => {
            string errorMsg = string `Unsupported database type: ${dbType}. Supported types are: h2, postgresql`;
            log:printError(errorMsg);
            return error(errorMsg);
        }
    }
}

# Sets the active database provider (called during initialization)
#
# + provider - The database provider to set as active
public function setActiveDatabaseProvider(DatabaseProvider provider) {
    lock {
        activeDatabaseProvider = provider;
    }
}

# Gets the active database provider instance
#
# + return - The active DatabaseProvider or error if not initialized
public function getActiveDatabaseProvider() returns DatabaseProvider|error {
    lock {
        DatabaseProvider? provider = activeDatabaseProvider;
        if provider is () {
            return error("Database provider not initialized. Call setActiveDatabaseProvider first.");
        }
        return provider;
    }
}

# Validates if the given database type is supported.
#
# + dbType - The database type to validate
# + return - true if supported, false otherwise
public isolated function isSupportedDatabaseType(string dbType) returns boolean {
    string normalizedType = dbType.toLowerAscii().trim();
    return normalizedType == "h2" || normalizedType == "postgresql" || normalizedType == "postgres";
}

# Returns a list of all supported database types.
#
# + return - Array of supported database type names
public isolated function getSupportedDatabaseTypes() returns string[] {
    return ["h2", "postgresql"];
}
