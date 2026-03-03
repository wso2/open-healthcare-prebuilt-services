import ballerina_fhir_server.mappers;

import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/java.jdbc;

public class ReadHandler {
    private mappers:ReadMapper readMapper;

    public isolated function init() {
        self.readMapper = new mappers:ReadMapper();
    }

    // Main function to read a single resource by ID
    public isolated function readResource(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns json|error {
        log:printDebug(string `Reading ${resourceType}/${resourceId}`);

        // Use ReadMapper to fetch resource
        json|error resourceJson = self.readMapper.readResourceById(jdbcClient, resourceType, resourceId);

        if resourceJson is error {
            log:printError(string `Failed to read ${resourceType}/${resourceId}: ${resourceJson.message()}`);
            return resourceJson;
        }

        log:printDebug(string `Successfully read ${resourceType}/${resourceId}`);
        return resourceJson;
    }

    // Function to search resources with query parameters
    public isolated function searchResources(jdbc:Client? jdbcClient, string resourceType, map<string[]> queryParams, r4:PaginationContext? paginationContext = ()) returns json|error {
        log:printDebug(string `Searching ${resourceType} with ${queryParams.keys().length()} query parameter(s)`);

        // Use ReadMapper to search resources
        json|error searchResults = self.readMapper.searchResources(jdbcClient, resourceType, queryParams, paginationContext);

        if searchResults is error {
            log:printError(string `Search failed for ${resourceType}: ${searchResults.message()}`);
            return searchResults;
        }

        log:printDebug(string `Search completed for ${resourceType}`);
        return searchResults;
    }

    // Function to read all resources of a type (with optional limit)
    public isolated function readAllResources(jdbc:Client? jdbcClient, string resourceType, int? 'limit = ()) returns json|error {
        log:printDebug(string `Reading all ${resourceType} resources${('limit is int) ? string ` (limit: ${'limit})` : ""}`);

        // Use ReadMapper to fetch all resources
        json|error allResources = self.readMapper.readAllResources(jdbcClient, resourceType, 'limit);

        if allResources is error {
            log:printError(string `Failed to read all ${resourceType} resources: ${allResources.message()}`);
            return allResources;
        }

        log:printDebug(string `Successfully read all ${resourceType} resources`);
        return allResources;
    }

    // Function to check if a resource exists
    public isolated function checkResourceExists(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns boolean|error {
        log:printDebug(string `Checking if ${resourceType}/${resourceId} exists`);

        // Use ReadMapper to check existence
        boolean|error exists = self.readMapper.resourceExists(jdbcClient, resourceType, resourceId);

        if exists is error {
            log:printError(string `Failed to check existence of ${resourceType}/${resourceId}: ${exists.message()}`);
            return exists;
        }

        log:printDebug(string `${resourceType}/${resourceId} ${exists ? "exists" : "does not exist"}`);
        return exists;
    }

    // Function to get resource count
    public isolated function getResourceCount(jdbc:Client? jdbcClient, string resourceType) returns int|error {
        log:printDebug(string `Getting count for ${resourceType} resources`);

        // Use ReadMapper to get count
        int|error count = self.readMapper.getResourceCount(jdbcClient, resourceType);

        if count is error {
            log:printError(string `Failed to get count for ${resourceType}: ${count.message()}`);
            return count;
        }

        log:printDebug(string `Total ${resourceType} resources: ${count}`);
        return count;
    }

    // Function to get resource metadata only (without full RESOURCE_JSON)
    public isolated function getResourceMetadata(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns record {|anydata...;|}|error {
        log:printDebug(string `Getting metadata for ${resourceType}/${resourceId}`);

        // Use ReadMapper to get metadata
        record {|anydata...;|}|error metadata = self.readMapper.getResourceMetadata(jdbcClient, resourceType, resourceId);

        if metadata is error {
            log:printError(string `Failed to get metadata for ${resourceType}/${resourceId}: ${metadata.message()}`);
            return metadata;
        }

        log:printDebug(string `Successfully retrieved metadata for ${resourceType}/${resourceId}`);
        return metadata;
    }

    // Function to read references for a resource
    public isolated function readResourceReferences(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns json[]|error {
        log:printDebug(string `Reading references for ${resourceType}/${resourceId}`);

        // Use ReadMapper to get references
        json[]|error references = self.readMapper.readReferences(jdbcClient, resourceType, resourceId);

        if references is error {
            log:printError(string `Failed to read references for ${resourceType}/${resourceId}: ${references.message()}`);
            return references;
        }

        log:printDebug(string `Successfully read ${references.length()} references for ${resourceType}/${resourceId}`);
        return references;
    }

    // Function to read resource with its references (combined operation)
    public isolated function readResourceWithReferences(jdbc:Client? jdbcClient, string resourceType, string resourceId) returns json|error {
        log:printDebug(string `Reading ${resourceType}/${resourceId} with references`);

        // Read the main resource
        json resourceJson = check self.readResource(jdbcClient, resourceType, resourceId);

        // Read associated references
        json[] references = check self.readResourceReferences(jdbcClient, resourceType, resourceId);

        // Combine resource and references into a single response
        json response = {
            "resource": resourceJson,
            "references": references
        };

        log:printDebug(string `Successfully read ${resourceType}/${resourceId} with ${references.length()} reference(s)`);
        return response;
    }

    // Function to fetch all resources referenced by a source resource (forward includes)
    public isolated function fetchAllReferencedResources(jdbc:Client? jdbcClient, string sourceResourceType, string sourceResourceId) returns json[]|error {
        log:printDebug(string `Fetching all resources referenced by ${sourceResourceType}/${sourceResourceId}`);

        // Use ReadMapper to fetch all referenced resources
        json[]|error references = self.readMapper.fetchAllReferencedResources(jdbcClient, sourceResourceType, sourceResourceId);

        if references is error {
            log:printError(string `Failed to fetch referenced resources for ${sourceResourceType}/${sourceResourceId}: ${references.message()}`);
            return references;
        }

        log:printDebug(string `Successfully fetched ${references.length()} referenced resource(s) for ${sourceResourceType}/${sourceResourceId}`);
        return references;
    }

    // Function to fetch all resources that reference a target resource (reverse includes)
    public isolated function fetchAllReferencingResources(jdbc:Client? jdbcClient, string targetResourceType, string targetResourceId) returns json[]|error {
        log:printDebug(string `Fetching all resources that reference ${targetResourceType}/${targetResourceId}`);

        // Use ReadMapper to fetch all referencing resources
        json[]|error references = self.readMapper.fetchAllReferencingResources(jdbcClient, targetResourceType, targetResourceId);

        if references is error {
            log:printError(string `Failed to fetch referencing resources for ${targetResourceType}/${targetResourceId}: ${references.message()}`);
            return references;
        }

        log:printDebug(string `Successfully fetched ${references.length()} referencing resource(s) for ${targetResourceType}/${targetResourceId}`);
        return references;
    }
}
