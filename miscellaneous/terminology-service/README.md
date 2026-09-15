# Ballerina FHIR Terminology Service

This project implements a FHIR R4 Terminology Service in Ballerina, providing RESTful APIs for managing and querying FHIR ValueSets and CodeSystems. It is designed to be compatible with HL7 FHIR R4 standards and supports key terminology operations such as expansion, validation, lookup, and subsumption.

## Features

- **ValueSet Operations**: Expand, validate, search, create, and retrieve ValueSets.
- **CodeSystem Operations**: Lookup, validate, subsume, search, create, and retrieve CodeSystems.
- **ConceptMap Operations**: Translate, search, create, and retrieve ConceptMaps.
- **Closure Table**: Maintain a client-named, incrementally-growing subsumption table via `$closure`.
- **Batch Validation**: Validate multiple ValueSets in a single request.
- **Upload**: Upload terminology resources in bulk.
- **Find Code**: Search for codes across CodeSystems and ValueSets.
- **FHIR CapabilityStatement**: Exposes service metadata for FHIR clients.

## API Endpoints

The service exposes the following main endpoints under `/fhir/r4`:

### ValueSet

- `GET /ValueSet/$expand` — Expand a ValueSet.
- `POST /ValueSet/$expand` — Expand a ValueSet with a POST body.
  - `ValueSet.compose.include.filter` supports `is-a` / `descendent-of`, `=`, and `regex`. Multiple filters on the same `include` are combined with AND (each narrows the same member set further), while multiple `include` entries are combined with OR.
  - `activeOnly=true` drops inactive concepts from the expansion and recomputes `expansion.total`.

- `GET /ValueSet/$validate-code` — Validate a code against a ValueSet.
- `POST /ValueSet/$validate-code` — Validate a code with a POST body.
  - Accepts either a `url` referencing an already-persisted ValueSet, or an inline `valueSet` resource in the request body — including one that was never separately uploaded.
- `GET /ValueSet/{id}/$expand` — Expand a ValueSet by ID.
- `GET /ValueSet/{id}/$validate-code` — Validate a code by ValueSet ID.
- `GET /ValueSet/{id}` — Retrieve a ValueSet by ID.
- `GET /ValueSet` — Search ValueSets.
- `POST /ValueSet` — Create a new ValueSet. `version` is optional, per the FHIR spec.

### CodeSystem

- `GET /CodeSystem/$lookup` — Lookup a code in a CodeSystem.
  - Returns one `parent` property per direct is-a parent (a concept can have more than one — e.g. SNOMED) and one `child` property per direct child, for CodeSystems that store hierarchy, along with the `abstract` and `inactive` flags derived from concept properties.
  - For SNOMED, also returns non-is-a clinical attribute relationships (e.g. Finding site, Associated morphology) as `property` entries, resolved from the imported Relationship data.

- `POST /CodeSystem/$lookup` — Lookup with a POST body.

- `GET /CodeSystem/$validate-code` — Validate a code against a CodeSystem.
- `POST /CodeSystem/$validate-code` — Validate a code with a POST body.
  - Accepts a `coding`, `codeableConcept`, or `code` (+`url`), validated against either a `url` referencing an already-persisted CodeSystem or an inline `codeSystem` resource in the request body — including one that was never separately uploaded.
  - A supplied `display` is checked against the matched concept's display and designations (synonyms count as a match); a mismatch returns `result: false` with a `message` explaining why.
- `GET /CodeSystem/$subsumes` — Test subsumption relationships.
- `POST /CodeSystem/$subsumes` — Test subsumption with a POST body.
- `GET /CodeSystem/{id}/$lookup` — Lookup by CodeSystem ID.
- `GET /CodeSystem/{id}/$validate-code` — Validate a code by CodeSystem ID.
- `GET /CodeSystem/{id}` — Retrieve a CodeSystem by ID.
- `GET /CodeSystem` — Search CodeSystems.
- `POST /CodeSystem` — Create a new CodeSystem. `version` is optional, per the FHIR spec.

### ConceptMap

- `GET /ConceptMap/$translate` — Translate a code from a source ValueSet to a target ValueSet.
- `POST /ConceptMap/$translate` — Translate with a POST body.
- `GET /ConceptMap/{id}` — Retrieve a ConceptMap by ID.
- `GET /ConceptMap` — Search ConceptMaps.
- `POST /ConceptMap` — Create a new ConceptMap.

### Other Operations

- `POST /` — Batch validate ValueSets.
- `POST /$upload` — Upload terminology resources.
- `POST /$upload` — Upload terminology resources as a zip. See [Uploading Terminology Content](#uploading-terminology-content).
- `POST /$closure` — [ConceptMap/$closure](https://hl7.org/fhir/R4/conceptmap-operation-closure.html): maintain a client-named, incrementally-growing subsumption closure table. Each call adds the given `concept`s to the named table (`name` parameter) and returns only the subsumption pairs not yet reported for that name. Pass a previously-returned `version` to resync everything reported since that version.
- `GET /$find-code` — Find codes.
- `POST /$find-code` — Find codes with a POST body.
- `GET /metadata` — Get the FHIR CapabilityStatement.

## Uploading Terminology Content

`POST /$upload` accepts a zip archive. Two things are required on the request:

- `Content-Type: application/zip`
- `x-terminology-type` header, set to `FHIR`, `LOINC`, or `SNOMED`

The header selects how the archive is interpreted. A missing or unrecognised value returns `400`.

### FHIR

Expects a zip of FHIR `CodeSystem-*.json` and `ValueSet-*.json` files. Loaded synchronously.

### LOINC

Expects a LOINC release zip. Converted to a FHIR CodeSystem and loaded synchronously.

- `loinc-version` (query parameter, optional) — version to record on the CodeSystem.

### SNOMED CT

Expects a SNOMED CT RF2 Snapshot release zip, containing the Concept, Description, Relationship and (optionally) Text Definition files.

- `snomed-version` (query parameter, optional) — RF2 release date as `YYYYMMDD`, recorded as the CodeSystem version.

**The import runs in the background.** The request returns `201 Created` as soon as the archive is extracted, before the concepts are loaded. A full release takes several minutes; check the server logs for progress and for the completion summary.

Re-uploading the same url and version replaces the previous load rather than duplicating it. If the import fails partway, the partial load is removed.

Concept hierarchy is stored in the `concept_closure` table as a transitive is-a closure, which supports `$subsumes` and the `is-a` / `descendent-of` filters on `$expand`.

## Usage

1. **Start the Service**: Run the Ballerina service (see below).
2. **Interact with the API**: Use tools like Postman or curl to send FHIR-compliant requests to the endpoints.
3. **Test Data**: Sample ValueSets, CodeSystems, and test payloads are available in the `tests/resources` directory.

## Running the Service

Ensure you have [Ballerina](https://ballerina.io/downloads/) installed. Then run:

```sh
bal run service.bal
```

The service will start on port `9090` by default.

## Project Structure

- `service.bal` — Main service implementation.
- `types.bal`, `utils.bal`, `data_mapping.bal`, etc. — Supporting modules and utilities.
- `modules/` — Contains submodules for LOINC, SNOMED, and persistence.
- `tests/` — Test cases and sample resources.

## Supported DB Types and Configurations

The following DB types are supported. 

- H2

```toml
[wso2.terminology_service]
db_type = "h2"
```
```toml
# When db_type is h2, use the following configuration values to connect to the database. Make sure to update the values accordingly.
[wso2.terminology_service.store_h2]
url = "database url"
user = "database user"
password = "database password"
```

- PostgreSQL

```toml
[wso2.terminology_service]
db_type = "postgresql" 
```
```toml
# When db_type is postgresql, use the following configuration values to connect to the database. Make sure to update the values accordingly.
[wso2.terminology_service.store_pg]
host = "database host"
database = "database name"
user = "database user name"
password = "database password"
port = 5432
```

## Conformance Test Suite

This service targets conformance with the HL7 FHIR Terminology Ecosystem IG's
test suite. See [tests/conformance-test-suite.md](tests/conformance-test-suite.md)
for how to point the suite at a running instance of this service and run it.

## References

- [HL7 FHIR Terminology Service Specification](https://hl7.org/fhir/terminology-service.html)
- [Ballerina FHIR Module](https://central.ballerina.io/ballerinax/health.fhir.r4)

## License

This project is licensed under the Apache License 2.0.

