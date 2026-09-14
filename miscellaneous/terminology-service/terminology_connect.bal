// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

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

import terminology_service.loinc_to_fhir as loinc;
import terminology_service.store_h2;

import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/regex;
import ballerina/time;
import ballerina/uuid;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.terminology;
import ballerinax/health.fhir.r4.validator;

final TerminologySource terminology_source = new TerminologySource();

// Serializes ConceptMap/$closure requests per table name. closurePost reads a
// closure table's currentVersion, computes newVersion = currentVersion + 1,
// and only commits that inside its own transaction - so two concurrent calls
// for the same table can both read the same currentVersion and race to
// record pairs under the same newVersion, with the loser's recordClosurePair
// failing on the unique pair index once the winner commits.
// acquireClosureTableLock/releaseClosureTableLock below make a second call
// for the same table name wait its turn instead of racing.
isolated map<boolean> closureTableLocks = {};

const decimal CLOSURE_LOCK_POLL_INTERVAL = 0.05;
const int CLOSURE_LOCK_MAX_POLLS = 600; // ~30s at CLOSURE_LOCK_POLL_INTERVAL

# Blocks (polling) until no other `$closure` call for `name` is in progress, then marks it as in progress. Different table names never block each other.
#
# + name - The closure table name to lock
# + return - An `r4:FHIRError` if the lock could not be acquired within the retry budget, `()` once acquired
isolated function acquireClosureTableLock(string name) returns r4:FHIRError? {
    int polls = 0;
    while polls < CLOSURE_LOCK_MAX_POLLS {
        boolean acquired = false;
        lock {
            if !closureTableLocks.hasKey(name) {
                closureTableLocks[name] = true;
                acquired = true;
            }
        }
        if acquired {
            return;
        }
        runtime:sleep(CLOSURE_LOCK_POLL_INTERVAL);
        polls += 1;
    }
    return r4:createFHIRError(
            string `Timed out waiting for the $closure table "${name}" to become available`,
            r4:ERROR,
            r4:PROCESSING,
            diagnostic = "Another $closure call for this table name is still in progress. Retry shortly.",
            httpStatusCode = http:STATUS_SERVICE_UNAVAILABLE);
}

# Releases the per-table `$closure` lock acquired via `acquireClosureTableLock`. Must be called exactly once per successful acquisition, regardless of whether the call succeeded or failed.
#
# + name - The closure table name to unlock
isolated function releaseClosureTableLock(string name) {
    lock {
        _ = closureTableLocks.removeIfHasKey(name);
    }
}

# Reads a `CodeSystem` by id, optionally pinned to a version encoded as `id|version`.
#
# + id - The `CodeSystem` id, optionally suffixed with `|version`
# + return - The matching `CodeSystem`, or a `FHIRError` if none is found
public isolated function readCodeSystemById(string id) returns r4:FHIRError|r4:CodeSystem|r4:FHIRError {
    string[] split = regex:split(id, string `\|`);
    string code_system_id = split[0];
    string? code_system_id_version = split.length() > 1 ? split[1] : ();

    return terminology:readCodeSystemById(id = code_system_id, version = code_system_id_version, terminology = terminology_source);
}

# Reads a `ValueSet` by id, optionally pinned to a version encoded as `id|version`.
#
# + id - The `ValueSet` id, optionally suffixed with `|version`
# + return - The matching `ValueSet`, or a `FHIRError` if none is found
public isolated function readValueSetById(string id) returns r4:ValueSet|r4:FHIRError {
    string[] split = regex:split(id, string `\|`);
    string value_set_id = split[0];
    string? value_set_id_version = split.length() > 1 ? split[1] : ();

    return terminology:readValueSetById(id = value_set_id, version = value_set_id_version, terminology = terminology_source);
}

# Reads a `CodeSystem` by canonical url, optionally pinned to a version encoded as `url|version`.
#
# + url - The `CodeSystem` canonical url, optionally suffixed with `|version`
# + return - The matching `CodeSystem`, or a `FHIRError` if none is found
public isolated function readCodeSystemByUrl(string url) returns r4:CodeSystem|r4:FHIRError {
    string[] split = regex:split(url, string `\|`);
    string code_system_url = split[0];
    string? code_system_url_version = split.length() > 1 ? split[1] : ();

    return terminology:readCodeSystemByUrl(url = code_system_url, version = code_system_url_version, terminology = terminology_source);
}

# Reads a `ValueSet` by canonical url, optionally pinned to a version encoded as `url|version`.
#
# + url - The `ValueSet` canonical url, optionally suffixed with `|version`
# + return - The matching `ValueSet`, or a `FHIRError` if none is found
public isolated function readValueSetByUrl(string url) returns r4:ValueSet|r4:FHIRError {
    string[] split = regex:split(url, string `\|`);
    string value_set_url = split[0];
    string? value_set_url_version = split.length() > 1 ? split[1] : ();

    return terminology:readValueSetByUrl(url = value_set_url, version = value_set_url_version, terminology = terminology_source);
}

# Reads a `ConceptMap` by canonical url, optionally pinned to a version encoded as `url|version`.
#
# + url - The `ConceptMap` canonical url, optionally suffixed with `|version`
# + return - The matching `ConceptMap`, or a `FHIRError` if none is found
public isolated function readConceptMapByUrl(string url) returns r4:ConceptMap|r4:FHIRError {
    string[] split = regex:split(url, string `\|`);
    string concept_map_url = split[0];
    string? concept_map_url_version = split.length() > 1 ? split[1] : ();

    return terminology:readConceptMap(conceptMapUrl = concept_map_url, version = concept_map_url_version, terminology = terminology_source);
}

# Reads a `ConceptMap` by id. The terminology library only exposes ConceptMap lookup by canonical url (readConceptMap) - there's no by-id counterpart like readCodeSystemById / readValueSetById - so this resolves directly against storage instead.
#
# + id - The `ConceptMap` id
# + return - The matching `ConceptMap`, or a `FHIRError` if none is found
public isolated function readConceptMapById(string id) returns r4:ConceptMap|r4:FHIRError {
    r4:ConceptMap[] results = check searchStoredConceptMaps({"_id": [createRequestSearchParameter("_id", id)]}, (), ());
    if results.length() == 0 {
        return r4:createFHIRError(
                "ConceptMap not found: " + id,
                r4:ERROR,
                r4:PROCESSING_NOT_FOUND,
                cause = error("No ConceptMap found for id " + id),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }
    return results[0];
}

# Handles the `ValueSet` search interaction, resolving the request's search parameters through the FHIR context and returning matches as a searchset `Bundle`.
#
# + ctx - The `FHIRContext` of the incoming search request
# + return - A searchset `Bundle` of matching `ValueSet` resources, or a `FHIRError` if the search parameters are invalid or the search fails
public isolated function searchValueSet(r4:FHIRContext ctx) returns r4:Bundle|r4:FHIRError {

    map<r4:RequestSearchParameter[]>|error params = getSearchParametersFromFHIRContext(ctx);

    if params is error {
        log:printError("Failed to get search parameters from FHIR context", 'error = params);
        return r4:createFHIRError(
                "Invalid search parameters",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = params,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:ValueSet[] valueSets = check terminology:searchValueSets(params, terminology = terminology_source);

    r4:BundleEntry[] entries = valueSets.'map(v => <r4:BundleEntry>{'resource: v, search: {mode: r4:MATCH}});

    return {
        'type: r4:BUNDLE_TYPE_SEARCHSET,
        meta: {
            lastUpdated: time:utcToString(time:utcNow())
        },
        total: entries.length(),
        entry: entries
    };
}

# Handles the `CodeSystem` search interaction, resolving the request's search parameters through the FHIR context and returning matches as a searchset `Bundle`.
#
# + ctx - The `FHIRContext` of the incoming search request
# + return - A searchset `Bundle` of matching `CodeSystem` resources, or a `FHIRError` if the search parameters are invalid or the search fails
public isolated function searchCodeSystem(r4:FHIRContext ctx) returns r4:Bundle|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly params = ctx.getRequestSearchParameters();
    map<r4:RequestSearchParameter[]>|error clonedParams = params.cloneWithType();

    if clonedParams is error {
        return r4:createFHIRError(
                "Invalid search parameters blah",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystem[] codeSystems = check terminology:searchCodeSystems(clonedParams, terminology = terminology_source);

    r4:BundleEntry[] entries = codeSystems.'map(c => <r4:BundleEntry>{'resource: c.toJson(), search: {mode: r4:MATCH}});

    return {
        'type: r4:BUNDLE_TYPE_SEARCHSET,
        meta: {
            lastUpdated: time:utcToString(time:utcNow())
        },
        total: entries.length(),
        entry: entries
    };
}

# Handles the `ConceptMap` search interaction, resolving the request's search parameters through the FHIR context and returning matches as a searchset `Bundle`.
#
# + ctx - The `FHIRContext` of the incoming search request
# + return - A searchset `Bundle` of matching `ConceptMap` resources, or a `FHIRError` if the search parameters are invalid or the search fails
public isolated function searchConceptMap(r4:FHIRContext ctx) returns r4:Bundle|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly params = ctx.getRequestSearchParameters();
    map<r4:RequestSearchParameter[]>|error clonedParams = params.cloneWithType();

    if clonedParams is error {
        return r4:createFHIRError(
                "Invalid search parameters",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:ConceptMap[] conceptMaps = check terminology:searchConceptMaps(clonedParams, terminology = terminology_source);

    r4:BundleEntry[] entries = conceptMaps.'map(c => <r4:BundleEntry>{'resource: c.toJson(), search: {mode: r4:MATCH}});

    return {
        'type: r4:BUNDLE_TYPE_SEARCHSET,
        meta: {
            lastUpdated: time:utcToString(time:utcNow())
        },
        total: entries.length(),
        entry: entries
    };
}

# TEMPORARY SHIM (branch: api-conformance). Filters an expansion request's search parameters down to the set natively supported by the terminology library (url, valueSetVersion, filter, _offset, _count), mapping the common aliases count -> _count and offset -> _offset. The terminology library returns a hard error ("Invalid search parameter: ...") for anything else, but the HL7 tx-ecosystem test suite sends many additional parameters (excludeNested, activeOnly, includeDesignations, displayLanguage, property, ...). Dropping the unsupported ones here lets expansion return a 2xx result instead of a 500, so the suite can run end-to-end; tests that depend on the dropped parameters still fail on output comparison rather than failing the HTTP call. Remove this shim once the parameters are natively supported.
#
# + params - The full set of requested search parameters
# + return - Only the parameters natively supported by the terminology library, with aliases normalized
isolated function filterSupportedExpansionParams(map<r4:RequestSearchParameter[]> params) returns map<r4:RequestSearchParameter[]> {
    map<r4:RequestSearchParameter[]> supported = {};
    foreach var [key, value] in params.entries() {
        string normalized = key;
        if key == "count" {
            normalized = "_count";
        } else if key == "offset" {
            normalized = "_offset";
        }
        if normalized == "url" || normalized == "valueSetVersion" || normalized == "filter"
                || normalized == "_offset" || normalized == "_count" {
            r4:RequestSearchParameter[] renamed = [];
            foreach var p in value {
                string paramValue = p.value;
                if normalized == "_count" {
                    // terminology:valueSetExpansion hard-rejects a count above its
                    // own TERMINOLOGY_SEARCH_MAXIMUM_COUNT with a 413, instead of
                    // capping it. Clamp here instead, so a request
                    // that still gets fewer results than asked for still succeeds.
                    int|error requestedCount = int:fromString(paramValue);
                    if requestedCount is int && requestedCount > terminology:TERMINOLOGY_SEARCH_MAXIMUM_COUNT {
                        paramValue = terminology:TERMINOLOGY_SEARCH_MAXIMUM_COUNT.toString();
                    }
                }
                renamed.push({name: normalized, value: paramValue, 'type: p.'type, typedValue: p.typedValue});
            }
            supported[normalized] = renamed;
        }
    }
    return supported;
}

# Extracts the scalar value of a FHIR Parameters.parameter entry (value[x]) as a string.
#
# + paramItem - The JSON object for a single `Parameters.parameter` entry
# + return - The stringified `value[x]`, or `()` if the entry has no scalar value
isolated function extractBodyParamValue(map<json> paramItem) returns string? {
    foreach var [key, value] in paramItem.entries() {
        if key.startsWith("value") && (value is string || value is int || value is float || value is decimal || value is boolean) {
            return value.toString();
        }
    }
    return ();
}

# Fills in the parts of a `$expand` response the terminology library leaves out: the system on each entry, the abstract and inactive flags, an expansion identifier, and an echo of the request parameters used. Also drops inactive concepts when activeOnly or compose.inactive asks for it.
#
# + vs - The `ValueSet` returned by the expansion operation, to be enriched
# + sourceVs - The original `ValueSet` (with its `compose`) the expansion was generated from, if known
# + requestParams - The search parameters from the original expansion request
# + return - The enriched `ValueSet`
isolated function postProcessExpansion(r4:ValueSet vs, r4:ValueSet? sourceVs, map<r4:RequestSearchParameter[]> requestParams) returns r4:ValueSet {
    r4:ValueSet mutable = vs.clone();
    r4:ValueSetExpansion? expansion = mutable.expansion;
    if expansion is () {
        return mutable;
    }

    // expansion.identifier just marks which expansion response this is - unlike
    // the per-entry system/abstract/inactive back-fill below, it doesn't depend
    // on resolving a single uniform system across every compose.include, so it
    // must be set unconditionally.
    if expansion.identifier is () {
        expansion.identifier = "urn:uuid:" + uuid:createType4AsString();
    }

    string? csUrl = ();
    if sourceVs is r4:ValueSet {
        r4:ValueSetCompose? compose = sourceVs.compose;
        if compose is r4:ValueSetCompose {
            r4:ValueSetComposeInclude[] includes = compose.include;
            if includes.length() > 0 {
                string? firstSys = includes[0].system;
                boolean uniform = firstSys is string;
                foreach var inc in includes {
                    if inc.system != firstSys {
                        uniform = false;
                        break;
                    }
                }
                if uniform && firstSys is string {
                    csUrl = firstSys;
                }
            }
        }
    }

    r4:ValueSetExpansionContains[]? contains = expansion.contains;
    if contains is () {
        return mutable;
    }

    // The compose-based derivation above only looks at compose.include.system,
    // so it finds nothing for a ValueSet composed entirely of `valueSet`
    // references - those entries are already tagged with their own system
    // though, so derive a uniform system from the result itself as a fallback.
    if csUrl is () && contains.length() > 0 {
        string? firstEntrySystem = contains[0].system;
        if firstEntrySystem is string {
            boolean uniform = true;
            foreach var entry in contains {
                if entry.system != firstEntrySystem {
                    uniform = false;
                    break;
                }
            }
            if uniform {
                csUrl = firstEntrySystem;
            }
        }
    }

    // Resolve flags from each entry's own system when it has one - a mixed-system
    // expansion leaves csUrl unset above, but every entry is already
    // tagged with its own system by then, so gating this whole loop on a single
    // uniform csUrl would silently skip abstract/inactive/property backfill for
    // every entry whenever more than one system is involved. csUrl is only used
    // here to back-fill a missing per-entry system, never to override one.
    foreach int i in 0 ..< contains.length() {
        if contains[i].system is () && csUrl is string {
            contains[i].system = <r4:uri>csUrl;
        }

        r4:uri? entrySystem = contains[i].system;
        r4:code? entryCode = contains[i].code;
        if entrySystem is r4:uri && entryCode is r4:code {
            [boolean, boolean] flags = getConceptFlags(entrySystem, entryCode);
            if flags[0] {
                contains[i].'abstract = true;
            }
            if flags[1] {
                contains[i].inactive = true;
            }

            // R4 has no native `expansion.contains.property` element (added in R5) - represent
            // it via the documented R4<->R5 cross-version extension instead:
            // https://hl7.org/fhir/uv/tx-ecosystem/r4.html
            string? statusPropertyValue = getConceptStatusPropertyValue(entrySystem, entryCode);
            if statusPropertyValue is string {
                r4:CodeExtension codeSubExtension = {url: "code", valueCode: "status"};
                r4:CodeExtension valueSubExtension = {url: "value", valueCode: <r4:code>statusPropertyValue};
                r4:ExtensionExtension propertyExtension = {
                    url: "http://hl7.org/fhir/5.0/StructureDefinition/extension-ValueSet.expansion.contains.property",
                    extension: [codeSubExtension, valueSubExtension]
                };
                r4:Extension[] entryExtensions = contains[i].extension ?: [];
                entryExtensions.push(propertyExtension);
                contains[i].extension = entryExtensions;
            }
        }
    }

    // Drop inactive concepts when the client asked for activeOnly or the ValueSet says so
    boolean requestActiveOnly = false;
    r4:RequestSearchParameter[]? activeOnlyParam = requestParams["activeOnly"];
    if activeOnlyParam is r4:RequestSearchParameter[] && activeOnlyParam.length() > 0 {
        requestActiveOnly = activeOnlyParam[0].value == "true";
    }

    boolean composeExcludesInactive = false;
    if sourceVs is r4:ValueSet {
        r4:ValueSetCompose? sourceCompose = sourceVs.compose;
        if sourceCompose is r4:ValueSetCompose && sourceCompose.inactive is boolean
            && !<boolean>sourceCompose.inactive {
            composeExcludesInactive = true;
        }
    }

    if requestActiveOnly || composeExcludesInactive {
        r4:ValueSetExpansionContains[] filtered = [];
        foreach var entry in contains {
            if entry.inactive is boolean && <boolean>entry.inactive {
                continue;
            }
            filtered.push(entry);
        }
        expansion.contains = filtered;
        expansion.total = filtered.length();
    }

    // Preserve any parameter entries already set on the expansion we were
    // handed (e.g. used-valueset, seeded by expandInlineValueSetCompose's
    // caller for a resource resolved via that fallback) rather than discarding
    // them - nothing currently sets expansion.parameter before this function
    // runs otherwise, so this is a no-op for every other call site.
    r4:ValueSetExpansionParameter[] expParams = expansion.'parameter ?: [];

    // Echo back the requested count if client sent one - accepting both the
    // bare and FHIR-standard "_"-prefixed spellings, since
    // filterSupportedExpansionParams normalizes both for actual pagination
    // but a client that only ever sent "_count" would otherwise never get it
    // echoed back here.
    r4:RequestSearchParameter[]? countParam = requestParams["count"] ?: requestParams["_count"];
    if countParam is r4:RequestSearchParameter[] && countParam.length() > 0 {
        int|error countVal = int:fromString(countParam[0].value);
        if countVal is int {
            expParams.push({name: "count", valueInteger: countVal});
        }
    }

    // Echo back the requested offset if client sent one (see count, above)
    r4:RequestSearchParameter[]? offsetParam = requestParams["offset"] ?: requestParams["_offset"];
    if offsetParam is r4:RequestSearchParameter[] && offsetParam.length() > 0 {
        int|error offsetVal = int:fromString(offsetParam[0].value);
        if offsetVal is int {
            expParams.push({name: "offset", valueInteger: offsetVal});
        }
    }

    r4:RequestSearchParameter[]? excludeNestedParam = requestParams["excludeNested"];
    if excludeNestedParam is r4:RequestSearchParameter[] && excludeNestedParam.length() > 0 {
        expParams.push({name: "excludeNested", valueBoolean: excludeNestedParam[0].value == "true"});
    }

    if csUrl is string {
        r4:CodeSystem|r4:FHIRError csForVersion = readCodeSystemByUrl(csUrl);
        if csForVersion is r4:CodeSystem {
            string usedCs = csForVersion.version is string
                ? csUrl + "|" + <string>csForVersion.version
                : csUrl;
            expParams.push({name: "used-codesystem", valueUri: usedCs});
        }
    }

    r4:RequestSearchParameter[]? displayLangParam = requestParams["displayLanguage"];
    if displayLangParam is r4:RequestSearchParameter[] && displayLangParam.length() > 0 {
        expParams.push({name: "displayLanguage", valueString: displayLangParam[0].value});
    }

    if expParams.length() > 0 {
        expansion.'parameter = expParams;
    }
    return mutable;
}

# Handles the `ValueSet/$expand` operation invoked via GET (query-parameter form). Resolves the target ValueSet either by `id` (instance-level call) or by the `url` query parameter (type-level call), expands it, and enriches the result via `postProcessExpansion`.
#
# + ctx - The `FHIRContext` of the incoming request, used to read the expansion query parameters
# + id - The `ValueSet` id for an instance-level `$expand`, or `()` for a type-level call driven by the `url` parameter
# + return - The expanded `ValueSet`, or a `FHIRError` if the ValueSet can't be resolved or expansion fails
public isolated function valueSetExpansionGet(r4:FHIRContext ctx, string? id = ()) returns r4:ValueSet|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly searchParameters = ctx.getRequestSearchParameters();
    map<r4:RequestSearchParameter[]> mutableParams = {};
    foreach var [k, v] in searchParameters.entries() {
        mutableParams[k] = v;
    }

    string? system = searchParameters["url"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParameters["url"])[0].value : ();
    map<r4:RequestSearchParameter[]> supportedParams = filterSupportedExpansionParams(mutableParams);

    //return valueSet;
    r4:ValueSet valueSet;
    r4:ValueSet? sourceVs = ();
    if id is string {
        r4:ValueSet resolved = check readValueSetById(id);
        sourceVs = resolved;
        valueSet = check terminology:valueSetExpansion(supportedParams, vs = resolved, terminology = terminology_source);
    } else {
        if system is string {
            r4:ValueSet|r4:FHIRError vsResult = readValueSetByUrl(system);
            if vsResult is r4:ValueSet {
                sourceVs = vsResult;
            }
        }
        valueSet = check terminology:valueSetExpansion(supportedParams, system = system, terminology = terminology_source);
    }
    return postProcessExpansion(valueSet, sourceVs, mutableParams);
}

# Handles the `ValueSet/$expand` operation invoked via POST (`Parameters` resource body). Unlike `valueSetExpansionGet`, this also accepts an inline `valueSet` parameter carrying a full `ValueSet` (with its own `compose`) to expand directly, in addition to resolving by `id` or the `url` parameter. Also folds any other scalar parameters in the body into the search-parameter map used for expansion and post-processing.
#
# + ctx - The `FHIRContext` of the incoming request, used to read any query parameters alongside the body
# + parameters - The `$expand` request body, which may carry `url`, an inline `valueSet`, and other expansion parameters
# + id - The `ValueSet` id for an instance-level `$expand`, or `()` for a type-level call driven by the body
# + return - The expanded `ValueSet`, or a `FHIRError` if the ValueSet can't be resolved or expansion fails
public isolated function valueSetExpansionPost(r4:FHIRContext ctx, r4:Parameters parameters, string? id = ()) returns r4:ValueSet|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly searchParameters = ctx.getRequestSearchParameters();
    map<r4:RequestSearchParameter[]> mutableParams = {};
    foreach var [k, v] in searchParameters.entries() {
        mutableParams[k] = v;
    }

    r4:ValueSet? inlineValueSet = ();
    string? system = ();
    json paramsJson = parameters.toJson();
    json parametersArray = (paramsJson is map<json>) ? (paramsJson["parameter"] ?: []) : [];
    if parametersArray is json[] {
        foreach json paramItem in parametersArray {
            if paramItem !is map<json> {
                continue;
            }
            string paramName = paramItem["name"] is string ? <string>paramItem["name"] : "";
            if paramName == "valueSet" {
                json? resourceJson = paramItem["resource"];
                if resourceJson is map<json> {
                    r4:ValueSet|error vs = resourceJson.cloneWithType(r4:ValueSet);
                    if vs is r4:ValueSet {
                        inlineValueSet = vs;
                    }
                }
            } else if paramName == "url" {
                system = extractBodyParamValue(paramItem);
            } else {
                string? val = extractBodyParamValue(paramItem);
                if val is string {
                    mutableParams[paramName] = [{name: paramName, value: val, 'type: r4:STRING, typedValue: {modifier: ()}}];
                }
            }
        }
    }

    map<r4:RequestSearchParameter[]> supportedParams = filterSupportedExpansionParams(mutableParams);

    r4:ValueSet expansionResult;
    r4:ValueSet? sourceVs = ();

    if id is string {
        r4:ValueSet resolved = check readValueSetById(id);
        sourceVs = resolved;
        expansionResult = check terminology:valueSetExpansion(supportedParams, vs = resolved, terminology = terminology_source);
    } else if inlineValueSet is r4:ValueSet {
        sourceVs = inlineValueSet;
        expansionResult = check terminology:valueSetExpansion(supportedParams, vs = inlineValueSet, terminology = terminology_source);
    } else {
        if system is string {
            r4:ValueSet|r4:FHIRError vsResult = readValueSetByUrl(system);
            if vsResult is r4:ValueSet {
                sourceVs = vsResult;
            }
        }
        expansionResult = check terminology:valueSetExpansion(supportedParams, system = system, terminology = terminology_source);
    }

    return postProcessExpansion(expansionResult, sourceVs, mutableParams);

}

# Handles `ValueSet/$validate-code` invoked via POST (`Parameters` resource body), by delegating the lookup to `valueSetLookUpPost` and converting the result into a standard `result`/`message`/`display` validation `Parameters` response.
#
# + ctx - The `FHIRContext` of the incoming request
# + parameters - The `$validate-code` request body
# + return - A `Parameters` resource describing whether the code is valid in the ValueSet, or a `FHIRError` if the request itself is invalid
public isolated function valueSetValidateCodePost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:Parameters|r4:FHIRError concept = valueSetLookUpPost(ctx, parameters);
    return validationResultToParameters(concept);
}

# Handles `ValueSet/$validate-code` invoked via GET (query-parameter form), by delegating the lookup to `valueSetLookUpGet` and converting the result into a standard `result`/`message`/`display` validation `Parameters` response.
#
# + ctx - The `FHIRContext` of the incoming request
# + id - The `ValueSet` id for an instance-level call, or `()` for a type-level call driven by query parameters
# + return - A `Parameters` resource describing whether the code is valid in the ValueSet, or a `FHIRError` if the request itself is invalid
public isolated function valueSetValidateCodeGet(r4:FHIRContext ctx, string? id = ()) returns r4:Parameters|r4:FHIRError {
    r4:Parameters|r4:FHIRError concept = valueSetLookUpGet(ctx, id);
    return validationResultToParameters(concept);
}

# Handles `CodeSystem/$lookup` invoked via GET (query-parameter form). Resolves the target CodeSystem either by `id` (instance-level call) or by the `system` query parameter (type-level call), looks up the `code`/`version` pair, and enriches the result with parent/child concepts and attribute relationships.
#
# + ctx - The `FHIRContext` of the incoming request, used to read the `system`, `code`, and `version` query parameters
# + id - The `CodeSystem` id for an instance-level `$lookup`, or `()` for a type-level call driven by the `system` parameter
# + return - A `Parameters` resource describing the looked-up concept, or a `FHIRError` if the code or CodeSystem can't be resolved
public isolated function codeSystemLookUpGet(r4:FHIRContext ctx, string? id = ()) returns r4:Parameters|r4:FHIRError {

    map<r4:RequestSearchParameter[] & readonly> & readonly idParam = ctx.getRequestSearchParameters();

    string? system = idParam["system"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["system"])[0].value : ();
    string? code = idParam["code"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["code"])[0].value : ();
    string? 'version = idParam["version"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["version"])[0].value : ();
    r4:code|r4:Coding? codeValue = code;

    if codeValue !is r4:code|r4:Coding {
        return r4:createFHIRError(
                "Invalid request payload, Code value is missing",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept result;
    r4:CodeSystem? cs = ();

    if id is string {
        r4:CodeSystem resolvedCs = check readCodeSystemById(id);
        cs = resolvedCs;
        result = check terminology:codeSystemLookUp(<r4:code>codeValue, system = resolvedCs.url ?: "", version = 'version, terminology = terminology_source);
    } else if system is string {
        r4:CodeSystem|r4:FHIRError csResult = readCodeSystemByUrl(system);
        if csResult is r4:CodeSystem {
            cs = csResult;
        }
        result = check terminology:codeSystemLookUp(<r4:code>codeValue, system = system, version = 'version, terminology = terminology_source);
    } else {
        return r4:createFHIRError(
                "Can not find a CodeSystem",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[] parentConcepts = [];
    r4:CodeSystemConcept[] childConcepts = [];
    ConceptAttributeRelationship[] attributeRelationships = [];
    if cs is r4:CodeSystem && cs.url is r4:uri {
        [r4:CodeSystemConcept[], r4:CodeSystemConcept[]] hierarchy =
                getConceptHierarchy(<r4:uri>cs.url, <r4:code>codeValue, 'version);
        parentConcepts = hierarchy[0];
        childConcepts = hierarchy[1];
        attributeRelationships = getConceptAttributeRelationships(<r4:uri>cs.url, <r4:code>codeValue, 'version);
    }

    return codesystemConceptsToParameters(result, cs, parentConcepts, childConcepts, attributeRelationships);
}

# Handles `CodeSystem/$lookup` invoked via POST (`Parameters` resource body). Accepts either a `coding` parameter or separate `system`/`code`/`version` parameters, looks up the concept, and enriches the result with parent/child concepts and attribute relationships.
#
# + ctx - The `FHIRContext` of the incoming request
# + parameters - The `$lookup` request body, carrying either a `coding` or `system`+`code`(+`version`)
# + return - A `Parameters` resource describing the looked-up concept, or a `FHIRError` if the code or CodeSystem can't be resolved
public isolated function codeSystemLookUpPost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:Coding? codingValue = ();
    r4:uri? system = ();
    r4:code? code = ();
    string? 'version = ();
    r4:CodeSystem? cs = ();

    r4:Parameters|error typedParams = parameters.toJson().cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if typedParams.'parameter is r4:ParametersParameter[] {
        // $lookup accepts EITHER a "coding" parameter OR separate "system"/"code"
        // (+ optional "version") parameters.
        foreach var item in <r4:ParametersParameter[]>typedParams.'parameter {
            match item.name {
                "coding" => {
                    codingValue = item.valueCoding;
                    if codingValue is r4:Coding && codingValue.system is r4:uri {
                        system = codingValue.system;
                    }
                }
                "system" => {
                    system = item.valueUri ?: item.valueString;
                }
                "code" => {
                    code = item.valueCode ?: item.valueString;
                }
                "version" => {
                    'version = item.valueString;
                }
            }
        }
    } else {
        return r4:createFHIRError(
                "Invalid request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept result;
    r4:code? effectiveCode = ();
    if codingValue is r4:Coding && system is string {
        result = check terminology:codeSystemLookUp(codingValue, system = system, version = 'version, terminology = terminology_source);
        effectiveCode = codingValue.code;
    } else if code is r4:code && system is string {
        result = check terminology:codeSystemLookUp(code, system = system, version = 'version, terminology = terminology_source);
        effectiveCode = code;
    } else {
        return r4:createFHIRError(
                "Can not find a CodeSystem",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "Provide either a 'coding' parameter or 'system' and 'code' parameters",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if system is r4:uri {
        r4:CodeSystem|r4:FHIRError csResult = readCodeSystemByUrl(system);
        if csResult is r4:CodeSystem {
            cs = csResult;
        }
    }

    r4:CodeSystemConcept[] parentConcepts = [];
    r4:CodeSystemConcept[] childConcepts = [];
    ConceptAttributeRelationship[] attributeRelationships = [];
    if system is r4:uri && effectiveCode is r4:code {
        [r4:CodeSystemConcept[], r4:CodeSystemConcept[]] hierarchy =
                getConceptHierarchy(system, effectiveCode, 'version);
        parentConcepts = hierarchy[0];
        childConcepts = hierarchy[1];
        attributeRelationships = getConceptAttributeRelationships(system, effectiveCode, 'version);
    }

    return codesystemConceptsToParameters(result, cs, parentConcepts, childConcepts, attributeRelationships);
}

# Handles `CodeSystem/$validate-code` invoked via POST (`Parameters` resource body). Accepts a `coding`, `codeableConcept`, or `code`(+`url`) to validate, against either an inline `codeSystem` resource or a CodeSystem resolved by `url`, converting the result into a standard `result`/`display`/`definition`(/`message`) validation `Parameters` response.
#
# + ctx - The `FHIRContext` of the incoming request
# + parameters - The `$validate-code` request body
# + return - A `Parameters` resource describing whether the code is valid in the CodeSystem, or a `FHIRError` if the request itself is invalid
public isolated function codeSystemValidateCodePost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:Coding? codingValue = ();
    r4:CodeableConcept? codeableConceptValue = ();
    r4:CodeSystem? inlineCodeSystem = ();
    r4:uri? url = ();
    r4:code? code = ();
    string? 'version = ();
    string? display = ();

    r4:Parameters|error typedParams = parameters.toJson().cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if typedParams.'parameter is r4:ParametersParameter[] {
        foreach var item in <r4:ParametersParameter[]>typedParams.'parameter {
            match item.name {
                "coding" => {
                    codingValue = item.valueCoding;
                }
                "codeableConcept" => {
                    codeableConceptValue = item.valueCodeableConcept;
                }
                "codeSystem" => {
                    anydata temp = item.'resource is r4:Resource ? item.'resource : ();
                    r4:CodeSystem|error cloneWithType = temp.cloneWithType(r4:CodeSystem);
                    if cloneWithType is r4:CodeSystem {
                        inlineCodeSystem = cloneWithType;
                    }
                }
                "url" => {
                    url = item.valueUri ?: item.valueString;
                }
                "code" => {
                    code = item.valueCode ?: item.valueString;
                }
                "version" => {
                    'version = item.valueString;
                }
                "display" => {
                    display = item.valueString;
                }
            }
        }
    } else {
        return r4:createFHIRError(
                "Invalid request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // terminology:codeSystemLookUp unconditionally casts cs.url to r4:uri with no
    // null check once a CodeSystem record is supplied - same class of issue as the
    // inline ValueSet case in valueSetLookUpPost. An inline "codeSystem" param is
    // (by definition) usually not separately persisted and often has no url.
    r4:CodeSystem? mutableInlineCodeSystem = inlineCodeSystem;
    if mutableInlineCodeSystem is r4:CodeSystem && mutableInlineCodeSystem.url is () {
        r4:CodeSystem withUrl = mutableInlineCodeSystem.clone();
        withUrl.url = "urn:uuid:" + uuid:createType1AsString();
        inlineCodeSystem = withUrl;
    }

    boolean isInlineCodeSystem = inlineCodeSystem is r4:CodeSystem;

    if codingValue is () && codeableConceptValue is () && code is r4:code {
        codingValue = <r4:Coding>{code: code};
    }

    if codingValue is () && codeableConceptValue is () {
        return r4:createFHIRError(
                "Can not find a valid code to validate",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "Provide (coding|codeableConcept) or (code), and (codeSystem resource) or (url).",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // "url" is the spec-correct way to identify the CodeSystem being checked
    // against, but a caller that already supplies a Coding (or a CodeableConcept
    // whose coding entries carry one) has effectively identified it too - fall
    // back to that system when no "url"/"codeSystem" was given, the same way
    // $lookup treats a coding's own system as sufficient.
    r4:uri? effectiveUrl = url;
    if effectiveUrl is () {
        if codingValue is r4:Coding && codingValue.system is r4:uri {
            effectiveUrl = codingValue.system;
        } else if codeableConceptValue is r4:CodeableConcept {
            foreach r4:Coding c in (codeableConceptValue.coding ?: []) {
                if c.system is r4:uri {
                    effectiveUrl = c.system;
                    break;
                }
            }
        }
    }

    r4:CodeSystem? cs = inlineCodeSystem;
    if cs is () && effectiveUrl is r4:uri {
        // readCodeSystemByUrl only pins a version when the url carries a
        // "|version" suffix - append the separately-supplied 'version here so
        // the resolved cs (used below for the response's system/version
        // metadata) actually matches the version being validated against,
        // instead of whatever version resolves by default.
        string urlToResolve = 'version is string ? effectiveUrl + "|" + 'version : effectiveUrl;
        r4:CodeSystem|r4:FHIRError csResult = readCodeSystemByUrl(urlToResolve);
        if csResult is r4:CodeSystem {
            cs = csResult;
        } else {
            return csResult;
        }
    }

    if cs is () {
        return r4:createFHIRError(
                "Can not find a CodeSystem",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "Provide either a 'codeSystem' resource or a 'url' parameter",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError result;
    r4:Coding|r4:CodeableConcept effectiveCodeValue;

    if codingValue is r4:Coding {
        effectiveCodeValue = codingValue;
        result = terminology:codeSystemLookUp(codingValue, cs = cs, version = 'version, terminology = terminology_source);
    } else {
        r4:CodeableConcept cc = <r4:CodeableConcept>codeableConceptValue;
        effectiveCodeValue = cc;
        result = r4:createFHIRError(
                "Can not find any valid concepts for the code: CodeableConcept has no coding",
                r4:ERROR,
                r4:PROCESSING_NOT_FOUND,
                httpStatusCode = http:STATUS_NOT_FOUND);
        foreach r4:Coding c in (cc.coding ?: []) {
            r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError attempt =
                    terminology:codeSystemLookUp(c, cs = cs, version = 'version, terminology = terminology_source);
            if attempt !is r4:FHIRError {
                result = attempt;
                break;
            }
            result = attempt;
        }
    }

    if result is r4:FHIRError && isInlineCodeSystem {
        result = lookupInInlineCodeSystem(effectiveCodeValue, <r4:CodeSystem>cs);
    }

    return validateCodeResultToParameters(cs, result, display);
}

# Handles `CodeSystem/$validate-code` invoked via GET (query-parameter form). Resolves the target CodeSystem by `id` (instance-level call) or the `url` query parameter (type-level call), validates the `code`/`version` pair, and converts the result into a standard `result`/`display`/`definition`(/`message`) validation `Parameters` response.
#
# + ctx - The `FHIRContext` of the incoming request, used to read the `url`, `code`, `version`, and `display` query parameters
# + id - The `CodeSystem` id for an instance-level call, or `()` for a type-level call driven by the `url` parameter
# + return - A `Parameters` resource describing whether the code is valid in the CodeSystem, or a `FHIRError` if the code or CodeSystem can't be resolved
public isolated function codeSystemValidateCodeGet(r4:FHIRContext ctx, string? id = ()) returns r4:Parameters|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly searchParams = ctx.getRequestSearchParameters();

    string? url = searchParams["url"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["url"])[0].value : ();
    string? code = searchParams["code"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["code"])[0].value : ();
    string? 'version = searchParams["version"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["version"])[0].value : ();
    string? display = searchParams["display"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["display"])[0].value : ();

    r4:code? codeValue = code;
    if codeValue !is r4:code {
        return r4:createFHIRError(
                "Can not find a CodeSystem, Code value is missing",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // readCodeSystemById/ByUrl only pin a version when the id/url carries a
    // "|version" suffix - append the separately-supplied 'version here so the
    // resolved cs (used below for the response's system/version metadata)
    // actually matches the version being validated against, instead of
    // whatever version resolves by default.
    r4:CodeSystem cs;
    if id is string {
        cs = check readCodeSystemById('version is string ? id + "|" + 'version : id);
    } else if url is string {
        cs = check readCodeSystemByUrl('version is string ? url + "|" + 'version : url);
    } else {
        return r4:createFHIRError(
                "Can not find a CodeSystem",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError result =
            terminology:codeSystemLookUp(<r4:code>codeValue, cs = cs, version = 'version, terminology = terminology_source);

    return validateCodeResultToParameters(cs, result, display);
}

# Shared tail for `codeSystemValidateCodeGet`/`codeSystemValidateCodePost`: converts a successful lookup to a `$lookup`-shaped `Parameters` via `codesystemConceptsToParameters`, collapses that into the standard `result`/`display`/`definition` validate-code shape via `validationResultToParameters`, and finally applies `applyDisplayCheck`. On a failed lookup, converts the `FHIRError` directly via `validationResultToParameters`.
#
# Deliberately does not compute parent/child hierarchy or attribute
# relationships the way `codeSystemLookUpGet`/`Post` do for `$lookup` -
# `validationResultToParameters` only reads `name`/`system`/`code`/`version`/`display`/`definition`, so that data would just be discarded.
#
# + cs - The CodeSystem the lookup was performed against, used for `$lookup`-style metadata
# + result - The concept(s) found by `terminology:codeSystemLookUp`/`lookupInInlineCodeSystem`, or the `FHIRError` if none matched
# + display - The caller-supplied `display` to check, or `()` if none was supplied
# + return - The final validate-code `Parameters` response, or a `FHIRError` if `validationResultToParameters` can't handle `result`
isolated function validateCodeResultToParameters(r4:CodeSystem cs, r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError result, string? display) returns r4:Parameters|r4:FHIRError {
    if result is r4:FHIRError {
        return validationResultToParameters(result);
    }

    r4:Parameters lookupParameters = codesystemConceptsToParameters(result, cs);
    r4:Parameters|r4:FHIRError validated = validationResultToParameters(lookupParameters);
    if validated is r4:FHIRError {
        return validated;
    }

    return applyDisplayCheck(validated, result, display);
}

# Recursively searches a CodeSystem's own inline `concept` list (including nested `concept` entries) for a code, for use when the terminology library can't resolve an inline `codeSystem` param by url (it only reads `cs.url`/`cs.version` and re-resolves from storage, the same limitation `lookupInInlineValueSet` works around for ValueSet).
#
# + codeValue - The `Coding` or `CodeableConcept` to look up
# + codeSystem - The inline `CodeSystem` (with its `concept` list) to search
# + return - The matching concept if found, or a `FHIRError` if no coding matches an entry in the CodeSystem
isolated function lookupInInlineCodeSystem(r4:Coding|r4:CodeableConcept codeValue, r4:CodeSystem codeSystem) returns r4:CodeSystemConcept|r4:FHIRError {
    r4:code[] codesToCheck = [];
    // Only consider a coding whose own system is unset or matches this
    // CodeSystem's url - otherwise a code that happens to collide with one
    // from a different system would wrongly validate against it.
    if codeValue is r4:Coding {
        r4:Coding coding = codeValue;
        if coding.code is r4:code && (coding.system is () || coding.system == codeSystem.url) {
            codesToCheck = [<r4:code>coding.code];
        }
    } else if codeValue is r4:CodeableConcept {
        foreach r4:Coding c in (codeValue.coding ?: []) {
            if c.code is r4:code && (c.system is () || c.system == codeSystem.url) {
                codesToCheck.push(<r4:code>c.code);
            }
        }
    }

    r4:CodeSystemConcept? found = findConceptInConceptList(codeSystem.concept ?: [], codesToCheck);
    if found is r4:CodeSystemConcept {
        return found;
    }

    // Message must match the "Can not find any valid concepts for the
    // code:.*" contract validationResultToParameters recognizes, so an
    // unknown inline code converts to a `result: false` Parameters response
    // instead of propagating as a raw 404 error.
    return r4:createFHIRError(
            "Can not find any valid concepts for the code: no matching concept found in the inline CodeSystem",
            r4:ERROR,
            r4:PROCESSING_NOT_FOUND,
            cause = error("No matching concept found in the inline CodeSystem"),
            httpStatusCode = http:STATUS_NOT_FOUND);
}

# Recursively walks a `CodeSystemConcept[]` list (and each concept's nested `concept[]`) for the first entry whose code appears in `codesToCheck`.
#
# + concepts - The concept list to search
# + codesToCheck - The candidate codes to match against
# + return - The matching concept, or `()` if none was found
isolated function findConceptInConceptList(r4:CodeSystemConcept[] concepts, r4:code[] codesToCheck) returns r4:CodeSystemConcept? {
    foreach r4:CodeSystemConcept concept in concepts {
        foreach r4:code candidate in codesToCheck {
            if concept.code == candidate {
                return concept;
            }
        }
        r4:CodeSystemConcept? nested = findConceptInConceptList(concept.concept ?: [], codesToCheck);
        if nested is r4:CodeSystemConcept {
            return nested;
        }
    }
    return ();
}

# Checks a supplied `display` param against the matched concept(s)' display and designations, patching an already-built validate-code `Parameters` response to `result: false` with a `message` part on mismatch. A mismatch against any designation value (not just the primary display) is still treated as a match, since synonyms are valid displays too.
#
# + validated - The `result`/`display`/`definition` `Parameters` produced by `validationResultToParameters`
# + concepts - The raw concept(s) the lookup matched, used to check display/designations
# + expectedDisplay - The caller-supplied `display` to check, or `()` if none was supplied
# + return - `validated` unchanged if `expectedDisplay` is `()` or matches; otherwise `validated` with `result` flipped to `false` and a `message` part added
isolated function applyDisplayCheck(r4:Parameters validated, r4:CodeSystemConcept[]|r4:CodeSystemConcept concepts, string? expectedDisplay) returns r4:Parameters {
    if expectedDisplay is () {
        return validated;
    }

    r4:CodeSystemConcept[] conceptList = concepts is r4:CodeSystemConcept[] ? concepts : [concepts];
    foreach r4:CodeSystemConcept concept in conceptList {
        if concept.display == expectedDisplay {
            return validated;
        }
        foreach r4:CodeSystemConceptDesignation designation in (concept.designation ?: []) {
            if designation.value == expectedDisplay {
                return validated;
            }
        }
    }

    string? actualDisplay = conceptList.length() > 0 ? conceptList[0].display : ();
    r4:ParametersParameter[] patchedParams = [];
    foreach r4:ParametersParameter p in (validated.'parameter ?: []) {
        if p.name == "result" {
            patchedParams.push({name: "result", valueBoolean: false});
        } else {
            patchedParams.push(p);
        }
    }
    patchedParams.push({
        name: "message",
        valueString: string `Display "${expectedDisplay}" does not match the expected display "${actualDisplay ?: ""}"`
    });

    return {'parameter: patchedParams};
}

# Checks whether codeValue is a Coding with no system, or a CodeableConcept containing at least one Coding with no system - either shape reaches the same unguarded cast inside the library's valueSetLookUp.
#
# + codeValue - The `Coding` or `CodeableConcept` to check
# + return - True if a system is missing from `codeValue` (or from any of its codings)
isolated function hasCodingWithoutSystem(r4:Coding|r4:CodeableConcept codeValue) returns boolean {
    if codeValue is r4:Coding {
        return codeValue.system is ();
    } else if codeValue is r4:CodeableConcept {
        foreach r4:Coding c in (codeValue.coding ?: []) {
            if c.system is () {
                return true;
            }
        }
    }
    return false;
}

# Looks up a coding against an inline ValueSet by expanding it and checking membership in the result. terminology:valueSetLookUp discards the ValueSet resource it's given beyond vs.url/vs.version - it re-resolves that url from storage rather than evaluating the compose actually supplied. An inline "valueSet" param sent in a $validate-code request is (by definition) usually not separately persisted, so that resolution fails even though the compose is already in hand. terminology:valueSetExpansion, unlike valueSetLookUp, does evaluate an inline resource's compose directly (that's how $expand already handles inline ValueSets correctly) - reuse it here and check membership in the result.
#
# + codeValue - The `Coding` or `CodeableConcept` to look up
# + valueSet - The inline `ValueSet` (with its `compose`) to expand and check membership against
# + return - The matching concept(s) if found, or a `FHIRError` if no coding matches an entry in the expansion
isolated function lookupInInlineValueSet(r4:Coding|r4:CodeableConcept codeValue, r4:ValueSet valueSet) returns r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError {
    r4:ValueSet expanded = check terminology:valueSetExpansion({}, vs = valueSet, terminology = terminology_source);
    r4:ValueSetExpansionContains[] contains = expanded.expansion?.contains ?: [];

    r4:Coding[] codingsToCheck = [];
    if codeValue is r4:Coding {
        codingsToCheck = [codeValue];
    } else if codeValue is r4:CodeableConcept {
        codingsToCheck = codeValue.coding ?: [];
    }
    r4:CodeSystemConcept[] matches = [];
    foreach r4:Coding c in codingsToCheck {
        foreach r4:ValueSetExpansionContains entry in contains {
            // Both entry.code and c.code are optional; entry.code is guarded
            // as r4:code first so a coding with no code can never match a
            // codeless expansion entry - () == () would otherwise be true,
            // and casting () to r4:code below would panic.
            r4:code? entryCode = entry.code;
            // expansion.contains entries only carry `system` when the include spans
            // multiple code systems (see postProcessExpansion, which back-fills it
            // for the single-system case after this call returns) - so only gate on
            // system when both sides actually have one to compare.
            if entryCode is r4:code && entryCode == c.code
                    && (entry.system is () || c.system is () || entry.system == c.system) {
                matches.push({code: entryCode, display: entry.display});
                break;
            }
        }
    }

    if matches.length() == 0 {
        return r4:createFHIRError(
                "Concept not found in the provided ValueSet",
                r4:ERROR,
                r4:PROCESSING_NOT_FOUND,
                cause = error("No matching concept found in the inline ValueSet"),
                httpStatusCode = http:STATUS_NOT_FOUND);
    }
    return matches.length() == 1 ? matches[0] : matches;
}

# Implements the code-in-ValueSet lookup behind `ValueSet/$validate-code` (POST form). Accepts a `coding` or `codeableConcept` (or `system`+`code`), matched against either an inline `valueSet` resource or a `ValueSet` resolved by `url`, and enriches the result with parent/child concepts and attribute relationships. Falls back to expanding an inline ValueSet's own `compose` (via `lookupInInlineValueSet`) when the library's own lookup can't resolve it by url.
#
# + ctx - The `FHIRContext` of the incoming request
# + parameters - The request body, carrying the code to look up and the ValueSet to check it against
# + return - A `Parameters` resource describing the matching concept(s), or a `FHIRError` if the inputs are invalid or no match is found
public isolated function valueSetLookUpPost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:Coding?|r4:CodeableConcept? codingValue = ();
    r4:ValueSet? valueSet = ();
    r4:uri? system = ();
    r4:code? code = ();
    r4:uri? valueSetUrl = ();
    string? 'version = ();

    r4:Parameters|error parse = parameters.toJson().cloneWithType(r4:Parameters);
    if parse is r4:Parameters && parse.'parameter is r4:ParametersParameter[] {
        foreach var item in <r4:ParametersParameter[]>parse.'parameter {
            match item.name {
                "coding" => {
                    codingValue = item.valueCoding;
                }
                "codeableConcept" => {
                    codingValue = item.valueCodeableConcept;
                }
                "valueSet" => {
                    anydata temp = item.'resource is r4:Resource ? item.'resource : ();
                    r4:ValueSet|error cloneWithType = temp.cloneWithType(r4:ValueSet);
                    if cloneWithType is r4:ValueSet {
                        valueSet = cloneWithType;
                    }
                }
                "system" => {
                    system = item.valueUri ?: item.valueString;
                }
                "code" => {
                    code = item.valueCode ?: item.valueString;
                }
                "url" => {
                    valueSetUrl = item.valueUri ?: item.valueString;
                }
                "version" => {
                    'version = item.valueString;
                }
            }
        }

        // terminology:valueSetLookUp unconditionally casts vs.url to r4:uri with
        // no null check - but ValueSet.url is optional per spec, and that's often
        // exactly why a caller passes an inline valueSet (an ad-hoc ValueSet with
        // no stable canonical url). Without this, an inline ValueSet with no url
        // panics with a raw TypeCastError instead of a handled FHIRError.
        r4:ValueSet? inlineValueSet = valueSet;
        if inlineValueSet is r4:ValueSet && inlineValueSet.url is () {
            r4:ValueSet mutableValueSet = inlineValueSet.clone();
            mutableValueSet.url = "urn:uuid:" + uuid:createType1AsString();
            valueSet = mutableValueSet;
        }
    } else {
        return r4:createFHIRError(
                "Invalid request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = parse is error ? parse : (),
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // If we don't have a Coding/CodeableConcept but we do have system+code, build one.
    if codingValue is () && system is r4:uri && code is r4:code {
        codingValue = <r4:Coding>{system: system, code: code};
    }

    // terminology:valueSetLookUp only ever reads vs.url/vs.version off the ValueSet
    // we pass it, then re-resolves that url from storage - it never evaluates the
    // compose we actually send. That's fine for a ValueSet resolved by url below
    // (it's already persisted under that exact url), but an inline "valueSet"
    // param is - by definition - usually not persisted, so that resolution would
    // always fail. Remember which case we're in before the url-resolution branch
    // below can overwrite valueSet.
    boolean isInlineValueSet = valueSet is r4:ValueSet;

    // If no inline ValueSet was supplied but url was, resolve it from storage.
    if valueSet is () && valueSetUrl is r4:uri {
        valueSet = check readValueSetByUrl(valueSetUrl);
    }

    if valueSet is r4:ValueSet && (codingValue is r4:Coding || codingValue is r4:CodeableConcept) {
        // terminology:valueSetLookUp force-casts each coding's system to a
        // non-nil type with no null check (see the library's utils.bal,
        // findConceptsInValueSetFromCodeValue) - a Coding with no system
        // panics the whole server instead of returning a handled error. Per
        // the FHIR spec (and the tx-ecosystem "no system" conformance test),
        // a Coding with no system simply can't be validated - short-circuit
        // to that clean, expected failure before ever reaching the call.
        if hasCodingWithoutSystem(codingValue) {
            return r4:createFHIRError(
                    "Can not find any valid concepts for the code: Coding has no system",
                    r4:ERROR,
                    r4:PROCESSING_NOT_FOUND,
                    diagnostic = "Coding has no system. A code with no system has no defined meaning, and it cannot be validated. A system should be provided.",
                    httpStatusCode = http:STATUS_NOT_FOUND);
        }

        // Try the library's own lookup first - when the inline ValueSet's url
        // happens to match something already persisted, this returns the full,
        // richly-populated concept (definition, properties, designations) that
        // our own storage-backed lookup produces. Only fall back to evaluating
        // the inline compose ourselves when that fails AND this was an inline
        // ValueSet - i.e. exactly the case the library can't resolve by url.
        r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError primary =
                terminology:valueSetLookUp(codingValue, vs = valueSet, terminology = terminology_source);
        r4:CodeSystemConcept[]|r4:CodeSystemConcept result;
        if primary is r4:FHIRError && isInlineValueSet {
            result = check lookupInInlineValueSet(codingValue, valueSet);
        } else {
            result = check primary;
        }

        r4:uri? effectiveSystem = codingValue is r4:Coding ? codingValue.system : system;
        r4:code? effectiveCode = codingValue is r4:Coding ? codingValue.code : code;

        r4:CodeSystemConcept[] parentConcepts = [];
        r4:CodeSystemConcept[] childConcepts = [];
        ConceptAttributeRelationship[] attributeRelationships = [];
        if effectiveSystem is r4:uri && effectiveCode is r4:code {
            [r4:CodeSystemConcept[], r4:CodeSystemConcept[]] hierarchy =
                    getConceptHierarchy(effectiveSystem, effectiveCode, 'version);
            parentConcepts = hierarchy[0];
            childConcepts = hierarchy[1];
            attributeRelationships = getConceptAttributeRelationships(effectiveSystem, effectiveCode, 'version);
        }

        return codesystemConceptsToParameters(result, parentConcepts = parentConcepts, childConcepts = childConcepts, attributeRelationships = attributeRelationships);
    }
    return r4:createFHIRError(
            "Invalid request payload",
            r4:ERROR,
            r4:INVALID_REQUIRED,
            diagnostic = "Provide (coding|codeableConcept) or (system+code), and (valueSet resource) or (url).",
            httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Implements the code-in-ValueSet lookup behind `ValueSet/$validate-code` (GET form). Resolves the target ValueSet by `id`, the `url` query parameter, or (as a legacy fallback) the `system` query parameter, then checks the given code for membership.
#
# + ctx - The `FHIRContext` of the incoming request, used to read the `url`/`system`/`code` query parameters
# + id - The `ValueSet` id for an instance-level call, or `()` to resolve the ValueSet by `url`/`system` instead
# + reqSystem - Fallback value for the code's system when not supplied as a `system` query parameter
# + reqCodeValue - Fallback value for the code when not supplied as a `code` query parameter
# + return - A `Parameters` resource describing the matching concept(s), or a `FHIRError` if the inputs are invalid or no match is found
public isolated function valueSetLookUpGet(r4:FHIRContext ctx, string? id = (), string? reqSystem = (), string? reqCodeValue = ()) returns r4:Parameters|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly searchParams = ctx.getRequestSearchParameters();
    // "url" is the spec-correct parameter for which ValueSet to validate against
    // (https://hl7.org/fhir/R4/valueset-operation-validate-code.html). "system"
    // is meant only for the code's own origin system, but earlier callers of
    // this GET path used "system" as a stand-in for the ValueSet url - kept as a
    // fallback so those callers don't break, with "url" taking precedence.
    string? url = searchParams["url"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["url"])[0].value : ();
    string? system = searchParams["system"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["system"])[0].value : reqSystem;
    r4:code? codeValue = searchParams["code"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>searchParams["code"])[0].value : reqCodeValue;

    if codeValue !is r4:code|r4:Coding|r4:CodeableConcept {
        return r4:createFHIRError(
                "Can not find a ValueSet, Code value is missing",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError result;
    if id is string {
        result = terminology:valueSetLookUp(<r4:code>codeValue, vs = check readValueSetById(id), terminology = terminology_source);
    } else if url is string {
        result = terminology:valueSetLookUp(<r4:code>codeValue, vs = check readValueSetByUrl(url), terminology = terminology_source);
    } else if system is string {
        result = terminology:valueSetLookUp(<r4:code>codeValue, vs = check readValueSetByUrl(system), terminology = terminology_source);
    } else {
        return r4:createFHIRError(
                "Can not find a ValueSet",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if result is r4:FHIRError {
        return result;
    }

    return codesystemConceptsToParameters(result);
}

# Handles `CodeSystem/$subsumes` invoked via GET (query-parameter form): checks the subsumption relationship between `codeA` and `codeB` within the given `system`/`version`.
#
# + ctx - The `FHIRContext` of the incoming request, used to read the `system`, `version`, `codeA`, and `codeB` query parameters
# + return - A `Parameters` resource carrying the subsumption `outcome`, or a `FHIRError` if any required parameter is missing
public isolated function subsumesGet(r4:FHIRContext ctx) returns r4:Parameters|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly idParam = ctx.getRequestSearchParameters();

    string? 'version = idParam["version"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["version"])[0].value : ();
    r4:uri? system = idParam["system"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["system"])[0].value : ();
    r4:code? codeA = idParam["codeA"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["codeA"])[0].value : ();
    r4:code? codeB = idParam["codeB"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>idParam["codeB"])[0].value : ();

    if system is string && codeA is r4:code && codeB is r4:code {
        // NOTE: replace the subsume function in terminology library by this subsume function
        // because this implementation is more efficient than the one in terminology library
        return terminology_source.subsumes(codeA = codeA, codeB = codeB, system = system, version = 'version);
    } else {
        return r4:createFHIRError(
                "Missing required input parameters",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
}

# Handles `CodeSystem/$subsumes` invoked via POST (`Parameters` resource body): checks the subsumption relationship between `codingA` and `codingB` within the given `system`/`version`.
#
# + ctx - The `FHIRContext` of the incoming request
# + parameters - The request body, carrying `codingA`, `codingB`, `system`, and optionally `version`
# + return - A `Parameters` resource carrying the subsumption `outcome`, or a `FHIRError` if any required parameter is missing
public isolated function subsumesPost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    string? 'version = ();
    r4:uri? system = ();
    r4:Coding? codingA = ();
    r4:Coding? codingB = ();

    r4:Parameters|error typedParams = parameters.toJson().cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // json|http:ClientError jsonPayload = request.getJsonPayload();
    if typedParams.'parameter is r4:ParametersParameter[] {
        foreach var item in <r4:ParametersParameter[]>typedParams.'parameter {
            match item.name {
                "codingA" => {
                    codingA = item.valueCoding ?: ();
                }

                "codingB" => {
                    codingB = item.valueCoding ?: ();
                }

                "version" => {
                    'version = item.valueString ?: ();
                }

                "system" => {
                    system = item.valueUri ?: ();
                }
            }
        }
    }

    if system is string && codingA is r4:Coding && codingB is r4:Coding {
        // NOTE: replace the subsume function in terminology library by this subsume function
        // because this implementation is more efficient than the one in terminology library
        return terminology_source.subsumes(codeA = <r4:code>codingA.code, codeB = <r4:code>codingB.code, system = system, version = 'version);
    } else {
        return r4:createFHIRError(
                "Missing required input parameters",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
}

# Converts an `OperationOutcome` into an `r4:FHIRError`. terminology:translate() returns r4:OperationOutcome (not r4:FHIRError) on failure, unlike the rest of this codebase's terminology:* calls; this bridges it into an r4:FHIRError so the $translate handlers can use the same check/error-propagation convention as every other operation here.
#
# + outcome - The `OperationOutcome` returned by a failed translate call
# + return - An `r4:FHIRError` built from the first issue's details/diagnostics, or a generic message if none are present
isolated function operationOutcomeToFHIRError(r4:OperationOutcome outcome) returns r4:FHIRError {
    string message = "Translation failed";
    r4:OperationOutcomeIssue[] issues = outcome.issue;
    if issues.length() > 0 {
        r4:CodeableConcept? details = issues[0].details;
        string? diagnostics = issues[0].diagnostics;
        if details is r4:CodeableConcept && details.text is string {
            message = <string>details.text;
        } else if diagnostics is string {
            message = diagnostics;
        }
    }
    return r4:createFHIRError(message, r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Validates required inputs and performs the `$translate` operation, shared by translateGet/translatePost once source/target/codesToTranslate have been extracted from the request. source is required because the underlying library function (terminology:translate) takes it as a non-nilable r4:uri - though the FHIR spec marks it merely "recommended," this server requires it.
#
# + sourceValueSetUri - The source ValueSet canonical URL, required
# + targetValueSetUri - The target ValueSet canonical URL, if known
# + codesToTranslate - The coding(s) to translate, required
# + return - The translation result `Parameters`, or a `FHIRError` if required inputs are missing or the translation fails
isolated function performTranslate(r4:uri? sourceValueSetUri, r4:uri? targetValueSetUri, r4:CodeableConcept? codesToTranslate) returns r4:Parameters|r4:FHIRError {
    if sourceValueSetUri is () {
        return r4:createFHIRError(
                "Missing required input parameter: source",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "The 'source' parameter (source ValueSet canonical URL) is required",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
    if codesToTranslate is () {
        return r4:createFHIRError(
                "Missing required input parameter",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "Provide one of: 'coding', 'codeableConcept', or 'code' + 'system'",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:Parameters|r4:OperationOutcome result = terminology:translate(sourceValueSetUri, targetValueSetUri, codesToTranslate, terminology = terminology_source);
    if result is r4:Parameters {
        return result;
    }
    return operationOutcomeToFHIRError(<r4:OperationOutcome>result);
}

# Handles `ConceptMap/$translate` invoked via GET (query-parameter form). Reads `source`/`target`(or `targetsystem`)/`system`/`code`/`version`, plus the non-standard `sourceSystem`/`sourceCode`/`targetSystem` aliases the tx-ecosystem test suite also sends, and delegates to `performTranslate`.
#
# + ctx - The `FHIRContext` of the incoming request, used to read the translate query parameters
# + return - The translation result `Parameters`, or a `FHIRError` if required inputs are missing or the translation fails
public isolated function translateGet(r4:FHIRContext ctx) returns r4:Parameters|r4:FHIRError {
    map<r4:RequestSearchParameter[] & readonly> & readonly params = ctx.getRequestSearchParameters();

    r4:uri? sourceValueSetUri = params["source"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["source"])[0].value : ();
    r4:uri? targetValueSetUri = params["target"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["target"])[0].value
        : (params["targetsystem"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["targetsystem"])[0].value : ());
    r4:uri? system = params["system"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["system"])[0].value : ();
    r4:code? code = params["code"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["code"])[0].value : ();
    string? 'version = params["version"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["version"])[0].value : ();

    // Non-standard convenience aliases the tx-ecosystem test suite also sends:
    // sourceSystem/targetSystem name the CodeSystem on each side directly
    // (rather than a ValueSet canonical url) - our ConceptMap matching treats
    // source/target as an opaque scope key either way, so this just widens
    // what can populate that key. sourceCode is the code being translated,
    // scoped by sourceSystem. Real source/system/code/target win if present.
    sourceValueSetUri = sourceValueSetUri ?: (params["sourceSystem"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["sourceSystem"])[0].value : ());
    targetValueSetUri = targetValueSetUri ?: (params["targetSystem"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["targetSystem"])[0].value : ());
    system = system ?: (params["sourceSystem"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["sourceSystem"])[0].value : ());
    code = code ?: (params["sourceCode"] is r4:RequestSearchParameter[] ? (<r4:RequestSearchParameter[]>params["sourceCode"])[0].value : ());

    r4:CodeableConcept? codesToTranslate = ();
    if code is r4:code && system is r4:uri {
        codesToTranslate = {coding: [{system: system, code: code, 'version: 'version}]};
    }

    return performTranslate(sourceValueSetUri, targetValueSetUri, codesToTranslate);
}

# Handles `ConceptMap/$translate` invoked via POST (`Parameters` resource body). Accepts `source`/`target`(or `targetsystem`)/`system`/`code`/`version`, or a `coding`/`codeableConcept`, plus the non-standard `sourceSystem`/`sourceCode`/`targetSystem` aliases the tx-ecosystem test suite also sends, and delegates to `performTranslate`.
#
# + ctx - The `FHIRContext` of the incoming request
# + parameters - The `$translate` request body
# + return - The translation result `Parameters`, or a `FHIRError` if required inputs are missing or the translation fails
public isolated function translatePost(r4:FHIRContext ctx, r4:Parameters parameters) returns r4:Parameters|r4:FHIRError {
    r4:uri? sourceValueSetUri = ();
    r4:uri? targetValueSetUri = ();
    r4:uri? system = ();
    r4:code? code = ();
    string? 'version = ();
    r4:Coding? codingValue = ();
    r4:CodeableConcept? codeableConceptValue = ();
    // Non-standard convenience aliases the tx-ecosystem test suite also sends
    // (see translateGet for why these are safe to treat as source/system/target).
    r4:uri? sourceSystemAlias = ();
    r4:code? sourceCodeAlias = ();
    r4:uri? targetSystemAlias = ();

    r4:Parameters|error typedParams = parameters.toJson().cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if typedParams.'parameter is r4:ParametersParameter[] {
        // $translate accepts EITHER a "coding" or "codeableConcept" parameter, OR
        // separate "system"/"code"(+"version") parameters, to identify the code(s)
        // being translated. "target" and "targetsystem" are aliases of each other
        // (a target ValueSet vs a target CodeSystem) - this server treats them the
        // same way, since findConceptMaps only matches on a single target scope.
        foreach var item in <r4:ParametersParameter[]>typedParams.'parameter {
            match item.name {
                "source" => {
                    sourceValueSetUri = item.valueUri ?: item.valueString;
                }
                "target" => {
                    targetValueSetUri = item.valueUri ?: item.valueString;
                }
                "targetsystem" => {
                    targetValueSetUri = targetValueSetUri ?: (item.valueUri ?: item.valueString);
                }
                "system" => {
                    system = item.valueUri ?: item.valueString;
                }
                "code" => {
                    code = item.valueCode ?: item.valueString;
                }
                "version" => {
                    'version = item.valueString;
                }
                "coding" => {
                    codingValue = item.valueCoding;
                }
                "codeableConcept" => {
                    codeableConceptValue = item.valueCodeableConcept;
                }
                "sourceSystem" => {
                    sourceSystemAlias = item.valueUri ?: item.valueString;
                }
                "sourceCode" => {
                    sourceCodeAlias = item.valueCode ?: item.valueString;
                }
                "targetSystem" => {
                    targetSystemAlias = item.valueUri ?: item.valueString;
                }
            }
        }
    } else {
        return r4:createFHIRError(
                "Invalid request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // Real source/system/code/target win if present; the aliases only fill gaps.
    sourceValueSetUri = sourceValueSetUri ?: sourceSystemAlias;
    targetValueSetUri = targetValueSetUri ?: targetSystemAlias;
    system = system ?: sourceSystemAlias;
    code = code ?: sourceCodeAlias;

    r4:CodeableConcept? codesToTranslate = ();
    if codeableConceptValue is r4:CodeableConcept {
        codesToTranslate = codeableConceptValue;
    } else if codingValue is r4:Coding {
        codesToTranslate = {coding: [codingValue]};
    } else if code is r4:code && system is r4:uri {
        codesToTranslate = {coding: [{system: system, code: code, 'version: 'version}]};
    }

    return performTranslate(sourceValueSetUri, targetValueSetUri, codesToTranslate);
}

# Processes a batch `Bundle` of `ValueSet/$validate-code`-style GET requests (each entry's `request.url` of the form `<base>?system=...&code=...`), validating each code against the ValueSet resolved from that system url, and returns a batch-response `Bundle` with one validation result per entry.
#
# + bundle - A `Bundle` whose type is "batch" and whose entries each request a code validation
# + return - A `Bundle` of type "batch-response" with one validation-result entry per input entry, or a `FHIRError` if the bundle isn't a valid batch
public isolated function batchValidateValueSets(r4:Bundle bundle) returns r4:Bundle|r4:FHIRError {

    if bundle.'type != r4:BUNDLE_TYPE_BATCH {
        return r4:createFHIRError(
                "Not a batch type bundle",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:BundleEntry[] responseEntries = [];
    r4:BundleEntry[]? entries = bundle.entry;
    if entries != () {
        foreach r4:BundleEntry entry in entries {
            if entry.request is r4:BundleEntryRequest {

                r4:BundleEntryRequest? entryRequest = entry.request;

                if entryRequest is () {
                    return r4:createFHIRError(
                            "No entry requests found in the bundle",
                            r4:ERROR,
                            r4:INVALID_REQUIRED,
                            httpStatusCode = http:STATUS_BAD_REQUEST);
                }

                // split the url to get system and code
                map<string> urlParts = getSystemAndCode(entryRequest.url);
                string? system = urlParts["system"];
                r4:code? code = urlParts["code"];

                r4:Parameters|r4:FHIRError result;
                if code is r4:code && system is string {
                    r4:CodeSystemConcept[]|r4:CodeSystemConcept|r4:FHIRError lookupResult = terminology:valueSetLookUp(code, vs = check readValueSetByUrl(system), terminology = terminology_source);
                    result = lookupResult is r4:FHIRError ? lookupResult : codesystemConceptsToParameters(lookupResult);
                } else {
                    result = r4:createFHIRError("Missing required parameters", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
                }

                if result is r4:Parameters {
                    responseEntries.push({
                        'resource: check validationResultToParameters(result)
                    });
                } else {
                    responseEntries.push({
                        'resource: <r4:Parameters>{
                            'parameter: [
                                {
                                    name: "result",
                                    valueBoolean: false
                                },
                                {
                                    name: "message",
                                    valueString: result.message()
                                }
                            ]
                        }
                    });
                }
            }
        }
    } else {
        return r4:createFHIRError(
                "No entries in the bundle",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    return {
        'type: r4:BUNDLE_TYPE_BATCH_RESPONSE,
        entry: responseEntries
    };
}

# Parses the `system` and `code` query parameters out of a bundle entry request URL of the form `<base>?system=...&code=...`.
#
# + input - The request URL to parse
# + return - A map with `system` and `code` entries when both are present in the query string, or an empty map if the URL has no query string
isolated function getSystemAndCode(string input) returns map<string> {
    // Split the string at '?' to separate the base URL and query parameters
    string[] parts = regex:split(input, string `\?`);

    if parts.length() < 2 {
        return {};
    }

    string queryParams = parts[1];

    // Split query parameters using '&'
    string[] params = regex:split(queryParams, string `&`);

    string system = "";
    string code = "";

    foreach var param in params {
        // Split each parameter by '='
        string[] keyValue = regex:split(param, string `=`);
        if keyValue.length() == 2 {
            if keyValue[0] == "system" {
                system = keyValue[1];
            } else if keyValue[0] == "code" {
                code = keyValue[1];
            }
        }
    }

    return {"system": system, "code": code};
}

# Validates and persists a new `CodeSystem`. Re-implements `terminology:addCodeSystem`'s url-check/validate/duplicate-check flow directly (rather than calling it) because that library function hard-rejects a `CodeSystem` with no version, while FHIR itself allows an unversioned `CodeSystem`.
#
# + ctx - The `FHIRContext` of the incoming create request
# + codeSystem - The `CodeSystem` to add
# + return - An `r4:FHIRError` if the `CodeSystem` has no url, fails validation, or already exists, `()` otherwise
public isolated function addCodeSystem(r4:FHIRContext ctx, r4:CodeSystem codeSystem) returns r4:FHIRError? {
    do {
        // Not using terminology:addCodeSystem directly: it hard-rejects a CodeSystem
        // with no version, but FHIR allows an unversioned CodeSystem. Re-implement
        // the same url-check/validate/duplicate-check flow, minus the version check.
        if codeSystem.url == () {
            return r4:createFHIRError(
                    string `Cannot find the URL of the CodeSystem with name: ${codeSystem.name.toString()}`,
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    diagnostic = string `Add a proper URL for the resource: http://hl7.org/fhir/R4/codesystem-definitions.html#CodeSystem.url`,
                    errorType = r4:VALIDATION_ERROR,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        r4:FHIRValidationError? validateResult = validator:validate(codeSystem.clone(), r4:CodeSystem);
        if validateResult is r4:FHIRValidationError {
            return r4:createFHIRError(
                    "Validation failed",
                    r4:ERROR,
                    r4:INVALID,
                    diagnostic = string `Check whether the data conforms to the specification: http://hl7.org/fhir/R4/codesystem-definitions.html`,
                    errorType = r4:VALIDATION_ERROR,
                    cause = validateResult,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        string url = <string>codeSystem.url;
        if terminology_source.isCodeSystemExist(url, codeSystem.version ?: "") {
            return r4:createFHIRError(
                    "Duplicate entry",
                    r4:ERROR,
                    r4:PROCESSING_DUPLICATE,
                    diagnostic = string `There is an already existing CodeSystem in the registry with the URL: ${url}`,
                    errorType = r4:PROCESSING_ERROR,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        return terminology_source.addCodeSystem(codeSystem.clone());
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Validates and persists a new `ValueSet`. Re-implements `terminology:addValueSet`'s url-check/validate/duplicate-check flow directly (rather than calling it) because that library function hard-rejects a `ValueSet` with no version, while FHIR itself allows an unversioned `ValueSet`.
#
# + ctx - The `FHIRContext` of the incoming create request
# + valueSet - The `ValueSet` to add
# + return - An `r4:FHIRError` if the `ValueSet` has no url, fails validation, or already exists, `()` otherwise
public isolated function addValueSet(r4:FHIRContext ctx, r4:ValueSet valueSet) returns r4:FHIRError? {
    do {
        // Not using terminology:addValueSet directly: it hard-rejects a ValueSet
        // with no version, but FHIR allows an unversioned ValueSet. Re-implement
        // the same url-check/validate/duplicate-check flow, minus the version check.
        if valueSet.url == () {
            return r4:createFHIRError(
                    string `Cannot find the URL of the ValueSet with name: ${valueSet.name.toString()}`,
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    diagnostic = "Add a proper URL for the resource: http://hl7.org/fhir/R4/valueset-definitions.html#ValueSet.url",
                    errorType = r4:VALIDATION_ERROR,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        r4:FHIRValidationError? validateResult = validator:validate(valueSet.clone(), r4:ValueSet);
        if validateResult is r4:FHIRValidationError {
            return r4:createFHIRError(
                    "Validation failed",
                    r4:ERROR,
                    r4:INVALID,
                    diagnostic = string `Check whether the data conforms to the specification: http://hl7.org/fhir/R4/valueset-definitions.html`,
                    errorType = r4:VALIDATION_ERROR,
                    cause = validateResult,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        string url = <string>valueSet.url;
        if terminology_source.isValueSetExist(url, valueSet.version ?: "") {
            return r4:createFHIRError(
                    "Duplicate entry",
                    r4:ERROR,
                    r4:PROCESSING_DUPLICATE,
                    diagnostic = string `Already there is a ValueSet exists in the registry with the URL: ${url}`,
                    errorType = r4:PROCESSING_ERROR,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        return terminology_source.addValueSet(valueSet.clone());
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Validates and persists a new `ConceptMap`. Round-trips the incoming resource through JSON before delegating to `terminology:addConceptMap`, because `ConceptMap` isn't a resource type the Terminology IG registers - the listener binds it against the default IG instead, producing a structurally identical but nominally different type that would otherwise trip up the library's internal `validator:validate(..., r4:ConceptMap)` call.
#
# + ctx - The `FHIRContext` of the incoming create request
# + conceptMap - The `ConceptMap` to add
# + return - An `r4:FHIRError` if the payload can't be normalized or the add fails, `()` otherwise
public isolated function addConceptMap(r4:FHIRContext ctx, r4:ConceptMap conceptMap) returns r4:FHIRError? {
    do {
        // Like byteToConceptMap in data_mapping.bal: ConceptMap isn't a resource
        // type the Terminology IG registers, so the fhirr4:Listener's own request
        // binding resolves it against the default (international401) IG. The
        // bound value is structurally identical to r4:ConceptMap but nominally a
        // different type, which trips up terminology:addConceptMap's internal
        // validator:validate(..., r4:ConceptMap) call. Re-derive a clean
        // r4:ConceptMap via JSON to sidestep the nominal mismatch.
        r4:ConceptMap normalized = check conceptMap.toJson().cloneWithType(r4:ConceptMap);
        return terminology:addConceptMap(normalized, terminology = terminology_source);
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Handles bulk upload of terminology content from a zip file, dispatched by the mandatory `${TYPE_HEADER}` header. FHIR content is loaded as raw CodeSystem/ValueSet JSON; LOINC content is converted to FHIR then added as a single `CodeSystem`; SNOMED content is imported asynchronously in the background (this call returns immediately with `()` while the import runs and logs its own completion).
#
# + payload - The incoming zip-file request, with the terminology type indicated by the `${TYPE_HEADER}` header
# + return - An `r4:FHIRError` if the payload is missing, has an unsupported content type/header, or fails to process, `()` otherwise
public isolated function upload(http:Request payload) returns r4:FHIRError? {
    if payload.getContentType() != ZIP {
        return r4:createFHIRError(
                "Invalid request payload, content type is not supported",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "The request payload should be a zip file",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    do {
        string|error typeHeader = payload.getHeader(TYPE_HEADER);

        if typeHeader is error {
            return r4:createFHIRError(
                    string `Missing ${TYPE_HEADER} header in the request`,
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    diagnostic = string `The request should contains ${TYPE_HEADER} header and supported values are: FHIR, LOINC and SNOMED`,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        else if typeHeader != FHIR && typeHeader != LOINC && typeHeader != SNOMED {
            return r4:createFHIRError(
                    string `Invalid ${TYPE_HEADER} header value`,
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    diagnostic = string `The request should contains ${TYPE_HEADER} header and supported values are: FHIR, LOINC and SNOMED`,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        string dirPath = createNewTempDirectory();

        check saveCompressedPayload(check payload.getByteStream(), dirPath);
        check extractZipFile(dirPath);

        r4:FHIRError? result = ();

        // standard FHIR
        if typeHeader == FHIR {
            CodeSystemValueSetJson jsonArrays = check readFilesForUpload(dirPath + ZIP_FILE_EXTRACTION_PATH);

            _ = terminology:addCodeSystemsAsJson(jsonArrays.codeSystems, terminology = terminology_source);
            _ = terminology:addValueSetsAsJson(jsonArrays.valueSets, terminology = terminology_source);
        }

        // LOINC
        else if typeHeader == LOINC {
            string? version = payload.getQueryParamValue("loinc-version");
            check loinc:convert(dirPath + ZIP_FILE_EXTRACTION_PATH, version);

            r4:CodeSystem codeSystem = check readFileJsonAndReturnCodeSystem(dirPath + ZIP_FILE_EXTRACTION_PATH + loinc:FHIR_LOINC_FILE_NAME);

            result = terminology:addCodeSystem(codeSystem, terminology = terminology_source);
        }

        // SNOMED
        else if typeHeader == SNOMED {
            if !tryAcquireSnomedImportLock() {
                _ = start removeDirectory(dirPath);
                return r4:createFHIRError(
                        "A SNOMED import is already in progress",
                        r4:ERROR,
                        r4:PROCESSING,
                        diagnostic = "Only one SNOMED import may run at a time. Wait for the current import to finish (check server logs) before retrying.",
                        httpStatusCode = http:STATUS_CONFLICT);
            }
            string? version = payload.getQueryParamValue("snomed-version");
            _ = start runSnomedImportAsync(dirPath + ZIP_FILE_EXTRACTION_PATH, version, dirPath);
            log:printInfo("SNOMED import scheduled in background; check server logs for completion.");
            return ();
        }

        _ = start removeDirectory(dirPath);

        return result;
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
}

# Handles the custom `$find-code` operation invoked via GET (query-parameter form): searches concepts across (optionally) a given `system` by matching `filter` text against either the `display` or `definition` property, paginated by `_count`/`_offset`.
#
# + request - The incoming HTTP request, read for the `property`, `system`, `filter`, `_count`, and `_offset` query parameters
# + return - A search-result `Bundle` of matching concepts, or a `FHIRError` if `filter` is missing, `property` is invalid, or the search fails
public isolated function findCodeGet(http:Request request) returns r4:Bundle|r4:FHIRError {
    string property = request.getQueryParamValue("property") ?: DISPLAY;
    string? system = request.getQueryParamValue("system");
    string? filter = request.getQueryParamValue("filter");
    int count;
    int offset;

    do {
        if filter is () {
            check error("Missing 'filter' query parameter");
        }

        if !(property == DISPLAY || property == DEFINITION) {
            check error("Invalid property value. Only 'display' or 'definition' are allowed.");
        }

        string? countStr = request.getQueryParamValue("_count");
        string? offsetStr = request.getQueryParamValue("_offset");

        count = countStr is string ? check int:fromString(countStr) : terminology:TERMINOLOGY_SEARCH_DEFAULT_COUNT;
        offset = offsetStr is string ? check int:fromString(offsetStr) : 0;
    } on fail var e {
        return r4:createFHIRError(
                "Invalid request payload, " + e.message(),
                r4:ERROR,
                r4:INVALID_REQUIRED,
                cause = e,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    terminology:CodeConceptDetails[]|r4:FHIRError result = terminology_source.searchConcept(<DISPLAY|DEFINITION>property, <string>filter, system, offset, count);

    if result is r4:FHIRError {
        return result;
    }

    return codeSystemDetailsIntoBundle(result);
}

# Implements `ConceptMap/$closure` (https://hl7.org/fhir/R4/conceptmap-operation-closure.html): maintains a client-named, incrementally-growing subsumption closure table. Each call adds the given `concept`s to the named table and returns only the subsumption pairs not yet reported for that name - both a new concept's own ancestors (via concept_closure, the same table `$subsumes`/`$lookup` already use), and any case where the new concept turns out to be an ancestor of a concept added in an earlier call. An optional `version` parameter also resyncs everything reported since that version.
#
# + request - The incoming HTTP request, whose JSON body is a `Parameters` resource carrying `name`, zero or more `concept` codings, and an optional `version` to resync from
# + return - A `ConceptMap` encoding the newly discovered (and, on resync, historical) subsumption pairs plus any unmatched concepts, or a `FHIRError` if the payload is invalid or `name` is missing
public isolated function closurePost(http:Request request) returns r4:ConceptMap|r4:FHIRError {
    json|http:ClientError jsonPayload = request.getJsonPayload();
    if jsonPayload is http:ClientError {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }
    r4:Parameters|error typedParams = jsonPayload.cloneWithType(r4:Parameters);
    if typedParams is error {
        return r4:createFHIRError("Invalid request payload", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    string? name = ();
    r4:Coding[] concepts = [];
    string? resyncVersion = ();

    if typedParams.'parameter is r4:ParametersParameter[] {
        foreach var item in <r4:ParametersParameter[]>typedParams.'parameter {
            match item.name {
                "name" => {
                    name = item.valueString;
                }
                "concept" => {
                    if item.valueCoding is r4:Coding {
                        concepts.push(<r4:Coding>item.valueCoding);
                    }
                }
                "version" => {
                    resyncVersion = item.valueString;
                }
            }
        }
    }

    if name is () {
        return r4:createFHIRError(
                "Missing required 'name' parameter",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                diagnostic = "$closure requires a 'name' parameter identifying the closure table",
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
    string closureName = name;

    // Serializes the whole read-modify-write below against other concurrent
    // $closure calls for the same table name: newVersion is derived from
    // tableRow.currentVersion read further down, and two concurrent calls for
    // the same table reading the same currentVersion before either commits
    // would otherwise race to record pairs under the same newVersion, with
    // the loser's recordClosurePair failing on the unique pair index once the
    // winner commits. acquireClosureTableLock makes a second call wait its
    // turn instead of racing (a plain Ballerina `lock` block can't be used
    // here: it forbids reading/writing any outer mutable variable - like
    // `concepts` or the arrays built up below - declared outside the block).
    check acquireClosureTableLock(closureName);

    // (ancestor, descendant) pairs newly discovered this call, plus any concepts
    // that couldn't be resolved.
    [int, int][] newPairs = [];
    UnmatchedClosureConcept[] unmatched = [];
    ClosureTableRow tableRow;
    int newVersion;
    ClosureTablePairRow[] pairsToReturn = [];

    do {
        tableRow = check getOrCreateClosureTable(closureName);
        newVersion = tableRow.currentVersion + 1;

        // Registering a concept as "known" (addClosureTableConcept) has to happen
        // before later concepts in this same call can be checked against it as a
        // reverse-descendant candidate (getDescendantConceptIdsAmong reads
        // closure_table_concepts), so the whole per-concept loop below - not just
        // the final bump/record step - has to run inside one DB transaction.
        // Otherwise a failure partway through (e.g. one concept's write fails, or
        // a pair-write fails after the version was already bumped) leaves earlier
        // writes committed: those concepts are "known" on retry, so their pairs
        // are never recomputed and are silently lost. Rolling back the whole
        // sequence together means a failed call leaves no partial state, so a
        // retry starts from exactly where the last successful call left off.
        transaction {
            int[] knownConceptIds = getKnownConceptIds(tableRow.closureTableId);

            foreach r4:Coding coding in concepts {
                string? system = coding.system;
                r4:code? code = coding.code;
                if system is () || code is () {
                    unmatched.push({system: system, code: code ?: ""});
                    continue;
                }

                store_h2:CodeSystem|error storeCs = getStoreCodeSystemByURL(system, coding.version);
                if storeCs is error {
                    unmatched.push({system: system, code: code});
                    continue;
                }
                store_h2:Concept|r4:FHIRError storeConcept = getStoreConceptByCode(storeCs.codeSystemId, code);
                if storeConcept is r4:FHIRError {
                    unmatched.push({system: system, code: code});
                    continue;
                }

                int conceptId = storeConcept.conceptId;
                if knownConceptIds.indexOf(conceptId) is int {
                    // Already added in an earlier call - nothing new to compute for it.
                    continue;
                }

                // This concept's own ancestors (is-a chain), whether or not those
                // ancestors were ever explicitly added by the client.
                int[] ancestorIds = getAncestorConceptIds(conceptId, storeCs.codeSystemId);
                foreach int ancestorId in ancestorIds {
                    newPairs.push([ancestorId, conceptId]);
                }

                // The reverse direction: this newly-added concept might itself be an
                // ancestor of a concept added in an earlier call, discovered only now.
                if knownConceptIds.length() > 0 {
                    int[] descendantIds = check getDescendantConceptIdsAmong(conceptId, storeCs.codeSystemId, tableRow.closureTableId);
                    foreach int descendantId in descendantIds {
                        newPairs.push([conceptId, descendantId]);
                    }
                }

                check addClosureTableConcept(tableRow.closureTableId, conceptId);
                knownConceptIds.push(conceptId);
            }

            check bumpClosureTableVersion(tableRow.closureTableId, newVersion);

            foreach [int, int] [ancestorId, descendantId] in newPairs {
                boolean alreadyReported = isPairReported(tableRow.closureTableId, ancestorId, descendantId);
                if !alreadyReported {
                    check recordClosurePair(tableRow.closureTableId, ancestorId, descendantId, newVersion);
                    pairsToReturn.push({
                        closureTablePairId: 0,
                        closureTableId: tableRow.closureTableId,
                        ancestorConceptId: ancestorId,
                        descendantConceptId: descendantId,
                        reportedAtVersion: newVersion
                    });
                }
            }

            error? commitResult = commit;
            if commitResult is error {
                fail commitResult;
            }
        }
    } on fail var e {
        releaseClosureTableLock(closureName);
        if e is r4:FHIRError {
            return e;
        }
        return r4:createFHIRError(
                "Error committing closure table update: " + e.message(),
                r4:ERROR,
                r4:PROCESSING,
                cause = e,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    releaseClosureTableLock(closureName);

    // Resync: also include everything reported after the version the client
    // last synced to, in addition to whatever this call just discovered.
    if resyncVersion is string {
        int|error requestedVersion = int:fromString(resyncVersion);
        if requestedVersion is int {
            ClosureTablePairRow[] historicalPairs = getPairsSinceVersion(tableRow.closureTableId, requestedVersion, newVersion);
            foreach var p in historicalPairs {
                pairsToReturn.push(p);
            }
        }
    }

    return check buildClosureConceptMap(closureName, newVersion, pairsToReturn, unmatched);
}

# Handles the custom `$find-code` operation invoked via POST (`Parameters` resource body): searches concepts across (optionally) a given `system` by matching a `filter` text parameter against either the `display` or `definition` property, paginated by `_count`/`_offset`.
#
# + request - The incoming HTTP request, whose JSON body is a `Parameters` resource carrying `property`, `system`, `filter`, `_count`, and `_offset`
# + return - A search-result `Bundle` of matching concepts, or a `FHIRError` if the payload is invalid, `filter` is missing, or `property` is invalid
public isolated function findCodePost(http:Request request) returns r4:Bundle|r4:FHIRError {
    string property = DISPLAY;
    string? system = ();
    string? filter = ();
    int count = terminology:TERMINOLOGY_SEARCH_DEFAULT_COUNT;
    int offset = 0;

    json|http:ClientError jsonPayload = request.getJsonPayload();
    if jsonPayload is json {
        r4:Parameters|error parameters = jsonPayload.cloneWithType(r4:Parameters);
        if parameters is r4:Parameters && parameters.'parameter is r4:ParametersParameter[] {
            foreach var item in <r4:ParametersParameter[]>parameters.'parameter {
                match item.name {
                    "property" => {
                        property = item.valueString ?: DISPLAY;
                    }
                    "system" => {
                        system = item.valueString ?: ();
                    }
                    "filter" => {
                        filter = item.valueString ?: ();
                    }
                    "_count" => {
                        count = item.valueInteger is int ? <int>item.valueInteger : terminology:TERMINOLOGY_SEARCH_DEFAULT_COUNT;
                    }
                    "_offset" => {
                        offset = item.valueInteger is int ? <int>item.valueInteger : 0;
                    }
                }
            }
        } else {
            return r4:createFHIRError(
                    "Invalid request payload",
                    r4:ERROR,
                    r4:INVALID_REQUIRED,
                    cause = parameters is error ? parameters : (),
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
    } else {
        return r4:createFHIRError(
                "Empty request payload",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if filter is () {
        return r4:createFHIRError(
                "Missing 'filter' parameter",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if !(property == DISPLAY || property == DEFINITION) {
        return r4:createFHIRError(
                "Invalid property value. Only 'display' or 'definition' are allowed.",
                r4:ERROR,
                r4:INVALID_REQUIRED,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    terminology:CodeConceptDetails[]|r4:FHIRError result = terminology_source.searchConcept(<DISPLAY|DEFINITION>property, <string>filter, system, offset, count);

    if result is r4:FHIRError {
        return result;
    }

    return codeSystemDetailsIntoBundle(result);
}

