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
