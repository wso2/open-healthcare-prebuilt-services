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
import ballerinax/persist.sql as psql;

type SQLSyntax record {|
    psql:DataSourceSpecifics dataspecifics;
    string regexOperator;
|};

isolated SQLSyntax syntax = initializeDataSourceSpecs();

isolated function initializeDataSourceSpecs() returns SQLSyntax {
    match db_type {
        "mysql" => {
            return {
                dataspecifics: psql:MYSQL_SPECIFICS,
                regexOperator: " REGEXP "
            };
        }
        "postgresql" => {
            return {
                dataspecifics: psql:POSTGRESQL_SPECIFICS,
                regexOperator: " ~ "
            };
        }
        "mssql" => {
            return {
                dataspecifics: psql:MSSQL_SPECIFICS,
                regexOperator: " LIKE "
            };
        }
        "h2" => {
            return {
                dataspecifics: psql:H2_SPECIFICS,
                regexOperator: " REGEXP "
            };
        }
        _ => {
            return {
                dataspecifics: psql:POSTGRESQL_SPECIFICS,
                regexOperator: " ~ "
            };
        }
    }
}

isolated function escape(string value) returns string {
    lock {
        return syntax.dataspecifics.quoteOpen + value + syntax.dataspecifics.quoteClose;
    }
}

isolated function escapeToQuery(string value) returns sql:ParameterizedQuery {
    lock {
        string escapedValue = escape(value);
        return stringToParameterizedQuery(escapedValue);
    }
}

isolated function getRegexOperator() returns sql:ParameterizedQuery {
    lock {
        return stringToParameterizedQuery(syntax.regexOperator);
    }
}

isolated function getLimitClause(int count, int offset) returns sql:ParameterizedQuery {
    if db_type == "mssql" {
        return `OFFSET ${offset} ROWS FETCH NEXT ${count} ROWS ONLY`;
    } else {
        return `LIMIT ${count} OFFSET ${offset}`;
    }
}
