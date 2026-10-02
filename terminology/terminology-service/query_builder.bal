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

// Escape character used with LIKE, so that a `%` or `_` typed by a client into
// a `$expand` `filter` matches literally instead of acting as a wildcard. `!`
// rather than the more usual `\`, which several dialects treat specially inside
// string literals in its own right.
const string LIKE_ESCAPE_CHAR = "!";

// Characters that make an `$expand` `filter` value behave as a regular
// expression rather than as literal text: the in-memory matching path
// interpolates the value into a `.*<filter>.*` pattern, so a value containing
// any of these has no equivalent LIKE predicate. See `isPlainTextFilter`.
final readonly & string[] REGEX_METACHARACTERS = ["\\", ".", "[", "]", "{", "}", "(", ")", "*", "+", "?", "^", "$", "|"];

# Reports whether a `$expand` `filter` value means the same thing as literal
# text, i.e. contains nothing the regex path would interpret. Only such a value
# can be pushed into SQL as a LIKE predicate without changing which concepts
# match; anything else keeps the existing in-memory regex matching.
#
# + value - The client-supplied `filter` value
# + return - `true` if the value holds no regex metacharacters
isolated function isPlainTextFilter(string value) returns boolean {
    foreach string metacharacter in REGEX_METACHARACTERS {
        if value.includes(metacharacter) {
            return false;
        }
    }
    return true;
}

# Escapes LIKE wildcards in a literal so it matches as typed.
#
# + value - Literal text to be embedded in a LIKE pattern
# + return - The text with `!`, `%` and `_` prefixed by `LIKE_ESCAPE_CHAR`
isolated function escapeLikeWildcards(string value) returns string {
    string escaped = "";
    foreach string:Char character in value {
        if character == LIKE_ESCAPE_CHAR || character == "%" || character == "_" {
            escaped += LIKE_ESCAPE_CHAR;
        }
        escaped += character;
    }
    return escaped;
}

# Builds the SQL equivalent of the in-memory display filter used across the
# `$expand` paths - a case-insensitive "display contains this text" test - so
# that non-matching rows are dropped by the database instead of being read and
# de-serialized first.
#
# The `IS NULL` arm is deliberate: `displayMatchesTextFilter`, the in-memory form
# of this test, leaves a concept that has no display in the result rather than
# filtering it out. Keeping that here makes this purely a performance change;
# whether a display-less concept *should* survive a text filter is a separate
# question. The two must agree in every other respect too - see that function on
# why it searches rather than matching against a `.*<filter>.*` pattern.
#
# + displayColumn - The (already escaped, optionally table-qualified) display column
# + textFilter - Literal filter text; only valid for a value `isPlainTextFilter` accepts
# + return - An ` AND (...)` fragment ready to append to a WHERE clause
isolated function displayContainsFragment(sql:ParameterizedQuery displayColumn, string textFilter) returns sql:ParameterizedQuery {
    string pattern = "%" + escapeLikeWildcards(textFilter.toUpperAscii()) + "%";
    return sql:queryConcat(
            ` AND (`, displayColumn, ` IS NULL OR UPPER(`, displayColumn, `) LIKE ${pattern} ESCAPE '`,
            stringToParameterizedQuery(LIKE_ESCAPE_CHAR), `')`);
}

isolated function getLimitClause(int count, int offset) returns sql:ParameterizedQuery {
    if db_type == "mssql" {
        return `OFFSET ${offset} ROWS FETCH NEXT ${count} ROWS ONLY`;
    } else {
        return `LIMIT ${count} OFFSET ${offset}`;
    }
}
