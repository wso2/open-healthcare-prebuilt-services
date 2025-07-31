# Ballerina FHIR Terminology Service

This project implements a FHIR R4 Terminology Service in Ballerina, providing RESTful APIs for managing and querying FHIR ValueSets and CodeSystems. It is designed to be compatible with HL7 FHIR R4 standards and supports key terminology operations such as expansion, validation, lookup, and subsumption.

## Features

- **ValueSet Operations**: Expand, validate, search, create, and retrieve ValueSets.
- **CodeSystem Operations**: Lookup, subsume, search, create, and retrieve CodeSystems.
- **Batch Validation**: Validate multiple ValueSets in a single request.
- **Upload**: Upload terminology resources in bulk.
- **Find Code**: Search for codes across CodeSystems and ValueSets.
- **FHIR CapabilityStatement**: Exposes service metadata for FHIR clients.

## API Endpoints

The service exposes the following main endpoints under `/fhir/r4`:

### ValueSet

- `GET /ValueSet/$expand` — Expand a ValueSet.
- `POST /ValueSet/$expand` — Expand a ValueSet with a POST body.
- `GET /ValueSet/$validate-code` — Validate a code against a ValueSet.
- `POST /ValueSet/$validate-code` — Validate a code with a POST body.
- `GET /ValueSet/{id}/$expand` — Expand a ValueSet by ID.
- `GET /ValueSet/{id}/$validate-code` — Validate a code by ValueSet ID.
- `GET /ValueSet/{id}` — Retrieve a ValueSet by ID.
- `GET /ValueSet` — Search ValueSets.
- `POST /ValueSet` — Create a new ValueSet.

### CodeSystem

- `GET /CodeSystem/$lookup` — Lookup a code in a CodeSystem.
- `POST /CodeSystem/$lookup` — Lookup with a POST body.
- `GET /CodeSystem/$subsumes` — Test subsumption relationships.
- `POST /CodeSystem/$subsumes` — Test subsumption with a POST body.
- `GET /CodeSystem/{id}/$lookup` — Lookup by CodeSystem ID.
- `GET /CodeSystem/{id}` — Retrieve a CodeSystem by ID.
- `GET /CodeSystem` — Search CodeSystems.
- `POST /CodeSystem` — Create a new CodeSystem.

### Other Operations

- `POST /` — Batch validate ValueSets.
- `POST /$upload` — Upload terminology resources.
- `GET /$find-code` — Find codes.
- `POST /$find-code` — Find codes with a POST body.
- `GET /metadata` — Get the FHIR CapabilityStatement.

## Usage

1. **Start the Service**: Run the Ballerina service (see below).
2. **Interact with the API**: Use tools like Postman or curl to send FHIR-compliant requests to the endpoints.
3. **Test Data**: Sample ValueSets, CodeSystems, and test payloads are available in the `tests/resources` directory.

## Running the Service

Ensure you have [Ballerina](https://ballerina.io/downloads/) installed. Then run:

```sh
bal run service.bal
```

The service will start on port `9089` by default.

## Project Structure

- `service.bal` — Main service implementation.
- `types.bal`, `utils.bal`, `data_mapping.bal`, etc. — Supporting modules and utilities.
- `modules/` — Contains submodules for LOINC, SNOMED, and persistence.
- `tests/` — Test cases and sample resources.

## References

- [HL7 FHIR Terminology Service Specification](https://hl7.org/fhir/terminology-service.html)
- [Ballerina FHIR Module](https://central.ballerina.io/ballerinax/health.fhir.r4)

## License

This project is licensed under the Apache License 2.0.
