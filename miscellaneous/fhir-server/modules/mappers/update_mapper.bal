import ballerina_fhir_server.utils as mapperUtils;

import ballerina/log;
import ballerina/time;

import ballerinax/java.jdbc;

public class UpdateMapper {
    private json[] references;
    private final jdbc:Client? jdbcClient;

    public isolated function init(jdbc:Client? jdbcClient = ()) {
        self.references = [];
        self.jdbcClient = jdbcClient;
    }

    // Generic helper to build update record from extracted search parameters
    // Queries database schema to determine which columns exist in the table
    private isolated function buildUpdateRecord(
        string resourceType,
        map<json> extractedValues,
        byte[] resourceJsonBytes,
        int newVersion
    ) returns map<anydata>|error {
        
        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client is required for generic column mapping");
        }
        
        string tableName = mapperUtils:getTableName(resourceType);
        
        // Get actual column names from database schema
        string[] tableColumns = check mapperUtils:getTableColumns(jdbcConn, tableName);
        
        // Convert column names to a set for fast lookup
        map<boolean> columnSet = {};
        foreach string column in tableColumns {
            columnSet[column] = true;
        }
        
        map<anydata> updateRecord = {};
        
        // First, initialize all columns with null/default values (except primary key and created_at)
        foreach string column in tableColumns {
            // Skip primary key (never updated)
            string primaryKeyColumn = mapperUtils:getPrimaryKeyColumn(resourceType);
            if column == primaryKeyColumn {
                continue;
            }
            
            // Skip CREATED_AT (should never change on update)
            if column == "CREATED_AT" {
                continue;
            }
            
            // Skip metadata fields (they're added at the end)
            if column == "VERSION_ID" || column == "UPDATED_AT" || 
               column == "LAST_UPDATED" || column == "RESOURCE_JSON" {
                continue;
            }
            
            // Initialize with null for optional fields
            updateRecord[column] = ();
        }
        
        // Now populate with actual values from extractedValues
        foreach string searchParam in extractedValues.keys() {
            string dbColumn = mapperUtils:toDbColumnName(searchParam);
            
            // Only include if this column exists in the table
            if !columnSet.hasKey(dbColumn) {
                continue;
            }
            
            // Skip primary key and metadata fields
            string primaryKeyColumn = mapperUtils:getPrimaryKeyColumn(resourceType);
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
                        updateRecord[dbColumn] = dateResult;
                    } else {
                        // If not a simple date, parse as datetime and extract date part
                        time:Civil|error civilResult = time:civilFromString(valueStr);
                        if civilResult is time:Civil {
                            // Extract only the date part for DATE columns
                            time:Date extractedDate = {year: civilResult.year, month: civilResult.month, day: civilResult.day};
                            updateRecord[dbColumn] = extractedDate;
                        } else {
                            updateRecord[dbColumn] = ();
                        }
                    }
                } else {
                    updateRecord[dbColumn] = ();
                }
            } else {
                // String fields - only set if non-empty
                string strValue = value.toString();
                if strValue.trim().length() > 0 {
                    updateRecord[dbColumn] = strValue;
                }
                // If empty, leave as () which was initialized above
            }
        }
        
        time:Civil currentTime = time:utcToCivil(time:utcNow());
        
        // Add standard metadata fields (only if they exist in table)
        if columnSet.hasKey("VERSION_ID") {
            updateRecord["VERSION_ID"] = newVersion;
        }
        if columnSet.hasKey("UPDATED_AT") {
            updateRecord["UPDATED_AT"] = currentTime;
        }
        if columnSet.hasKey("LAST_UPDATED") {
            updateRecord["LAST_UPDATED"] = currentTime;
        }
        if columnSet.hasKey("RESOURCE_JSON") {
            updateRecord["RESOURCE_JSON"] = resourceJsonBytes;
        }
        
        return updateRecord;
    }

    // This function will map values to persist update models
    public isolated function mapToUpdateModel(jdbc:Client jdbcClient, string resourceType, json resourceJson, int newVersion = 2) returns record {|anydata...;|}|error? {
        FHIRMapper fhirMapper = new FHIRMapper();
        map<json> extractedValues = check fhirMapper.extractSearchParameters(jdbcClient, resourceType, resourceJson);
        self.references = fhirMapper.getReferences();

        // Use fully generic database-driven approach for all resources
        jdbc:Client? jdbcConn = self.jdbcClient;
        if jdbcConn is () {
            return error("JDBC client is required for resource mapping");
        }

        log:printDebug(string `Using generic mapping for ${resourceType} update`);
        log:printDebug(string `Extracted values: ${extractedValues.toString()}`);

        map<anydata> updateRecord = check self.buildUpdateRecord(
            resourceType,
            extractedValues,
            resourceJson.toJsonString().toBytes(),
            newVersion
        );

        return updateRecord;
    }

    public isolated function getReferences() returns json[] {
        return self.references;
    }
}
