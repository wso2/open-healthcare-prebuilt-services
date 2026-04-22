import ballerina_fhir_server.utils as mapperUtils;

import ballerina/log;
import ballerina/time;
import ballerinax/java.jdbc;

public class CreateMapper {
    private json[] references;
    private json resourceJsonWithId;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.references = [];
        self.resourceJsonWithId = {};
        self.jdbcClient = jdbcClient;
    }

    // Generic helper to build insert record from extracted search parameters
    // Queries database schema to determine which columns exist in the table
    private isolated function buildInsertRecord(
            string resourceType,
            string resourceId,
            map<json> extractedValues,
            anydata resourceJsonData
    ) returns map<anydata>|error {

        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client is required for generic column mapping");
        }

        string tableName = mapperUtils:getTableName(resourceType);
        log:printDebug("Building insert record for resource type: " + resourceType + ", table: " + tableName);

        // Get actual column names from database schema
        string[] tableColumns = check mapperUtils:getTableColumns(jdbcConn, tableName);

        log:printDebug("Retrieved " + tableColumns.length().toString() + " columns for table " + tableName);

        // Convert column names to a set for fast lookup
        map<boolean> columnSet = {};
        foreach string column in tableColumns {
            columnSet[column] = true;
        }

        map<anydata> insertRecord = {};

        // Add the resource ID (primary key)
        string primaryKeyColumn = mapperUtils:getPrimaryKeyColumn(resourceType);
        if columnSet.hasKey(primaryKeyColumn) {
            insertRecord[primaryKeyColumn] = resourceId;
        }

        // First, initialize all columns with null/default values
        foreach string column in tableColumns {
            // Skip primary key (already set)
            if column == primaryKeyColumn {
                continue;
            }

            // Skip metadata fields (they're added at the end)
            if column == "VERSION_ID" || column == "CREATED_AT" ||
                column == "UPDATED_AT" || column == "LAST_UPDATED" ||
                column == "RESOURCE_JSON" {
                continue;
            }

            // Initialize with null for optional fields
            insertRecord[column] = ();
        }

        // Now populate with actual values from extractedValues
        foreach string searchParam in extractedValues.keys() {
            string dbColumn = mapperUtils:toDbColumnName(searchParam);

            // Only include if this column exists in the table
            if !columnSet.hasKey(dbColumn) {
                continue;
            }

            // Skip if primary key or metadata
            if dbColumn == primaryKeyColumn || dbColumn == "VERSION_ID" ||
                dbColumn == "CREATED_AT" || dbColumn == "UPDATED_AT" ||
                dbColumn == "LAST_UPDATED" || dbColumn == "RESOURCE_JSON" {
                continue;
            }

            json value = extractedValues.get(searchParam);

            // Determine field type based on parameter name patterns
            if searchParam.endsWith("date") || searchParam == "period" ||
                searchParam == "effective" || searchParam == "authored" || searchParam == "authoredon" ||
                searchParam == "created" || searchParam == "started" || searchParam == "issued" || searchParam == "recorded" {
                // Handle date fields
                string valueStr = value.toString();
                if valueStr.trim().length() > 0 {
                    // Try to parse as date first
                    time:Date|error dateResult = mapperUtils:parseDateString(valueStr);
                    if dateResult is time:Date {
                        insertRecord[dbColumn] = dateResult;
                    } else {
                        // If not a simple date, parse as datetime and extract date part
                        time:Civil|error civilResult = time:civilFromString(valueStr);
                        if civilResult is time:Civil {
                            // Extract only the date part for DATE columns
                            time:Date extractedDate = {year: civilResult.year, month: civilResult.month, day: civilResult.day};
                            insertRecord[dbColumn] = extractedDate;
                        } else {
                            insertRecord[dbColumn] = ();
                        }
                    }
                } else {
                    insertRecord[dbColumn] = ();
                }
            } else {
                // String fields - only set if non-empty
                string strValue = value.toString();
                if strValue.trim().length() > 0 {
                    insertRecord[dbColumn] = strValue;
                }
                // If empty, leave as () which was initialized above
            }
        }

        // Add standard metadata fields (only if they exist in table)
        if columnSet.hasKey("VERSION_ID") {
            insertRecord["VERSION_ID"] = 1;
        }

        time:Civil currentTime = time:utcToCivil(time:utcNow());

        if columnSet.hasKey("CREATED_AT") {
            insertRecord["CREATED_AT"] = currentTime;
        }
        if columnSet.hasKey("UPDATED_AT") {
            insertRecord["UPDATED_AT"] = currentTime;
        }
        if columnSet.hasKey("LAST_UPDATED") {
            insertRecord["LAST_UPDATED"] = currentTime;
        }
        if columnSet.hasKey("RESOURCE_JSON") {
            insertRecord["RESOURCE_JSON"] = resourceJsonData;
        }

        return insertRecord;
    }

    // This function will map values to persist insert models
    public isolated function mapToInsertModel(jdbc:Client jdbcClient, string resourceType, json resourceJson) returns record {|anydata...;|}|error? {
        FHIRMapper fhirMapper = new FHIRMapper();
        map<json> extractedValues = check fhirMapper.extractSearchParameters(jdbcClient, resourceType, resourceJson);
        self.references = fhirMapper.getReferences();

        // Use fully generic database-driven approach for all resources
        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client is required for resource mapping");
        }

        log:printDebug(string `Using generic mapping for ${resourceType}`);

        // Determine resource ID based on configuration
        string resourceId;
        if mapperUtils:useServerGeneratedIds {
            // Server generates the ID
            resourceId = mapperUtils:generateResourceId();
            log:printDebug(string `Generated server ID for ${resourceType}: ${resourceId}`);
        } else {
            // Use client-provided ID
            json|error clientId = resourceJson.id;
            if clientId is error {
                return error("Resource must have an 'id' field when server-generated IDs are disabled");
            }
            resourceId = clientId.toString();
            log:printDebug(string `Using client-provided ID for ${resourceType}: ${resourceId}`);
        }

        // Inject generated ID into resource JSON so RESOURCE_JSON stored in DB includes the id
        map<json> resourceJsonMap = check resourceJson.cloneWithType();
        resourceJsonMap["id"] = resourceId;
        json resourceJsonWithId = resourceJsonMap.toJson();
        self.resourceJsonWithId = resourceJsonWithId;

        string normalizedDbType = mapperUtils:dbType.toLowerAscii().trim();
        anydata resourceJsonData = (normalizedDbType == "postgresql" || normalizedDbType == "postgres")
            ? resourceJsonWithId.toJsonString()
            : resourceJsonWithId.toJsonString().toBytes();

        map<anydata> insertRecord = check self.buildInsertRecord(
            resourceType,
            resourceId,
            extractedValues,
            resourceJsonData
        );

        return insertRecord;
    }

    public isolated function getReferences() returns json[] {
        return self.references;
    }

    public isolated function getResourceJsonWithId() returns json {
        return self.resourceJsonWithId;
    }
}
