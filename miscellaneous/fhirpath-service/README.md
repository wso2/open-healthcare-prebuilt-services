# FHIRPath Service

This service is a Ballerina-based API for evaluating [FHIRPath](https://hl7.org/fhir/fhirpath.html) expressions against FHIR R4 resources. It provides endpoints to **extract values** from and **set values** in FHIR resources using FHIRPath expressions, powered by the `ballerinax/health.fhir.r4utils.fhirpath` library.

## Features

- **Get Values**: Extract one or more values from a FHIR resource using FHIRPath expressions.
- **Set Values**: Update, add, or remove values in a FHIR resource at specified FHIRPath locations.
- **Batch FHIRPath Evaluation**: Evaluate multiple FHIRPath expressions in a single request.
- **Optional Resource Validation**: Optionally validate input and/or output FHIR resources.

## Prerequisites

To get started with this service, you'll need to have Ballerina (refer to compatibility to install the relevant version) installed on your machine.

## Setup and Run

1. Clone this repository to your local machine and navigate to the `fhirpath-service` directory.

2. Run the project.

    ```bash
    bal run
    ```

    The service will start on port `9090` by default.

## API Reference

### POST /fhirpath/get

Extract values from a FHIR resource using one or more FHIRPath expressions.

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `fhirResource` | `json` | Yes | The FHIR resource to evaluate against. |
| `fhirPath` | `string` or `string[]` | Yes | One or more FHIRPath expressions to evaluate. |
| `validateInputFHIRResource` | `boolean` | No | Whether to validate the input FHIR resource before evaluation. Defaults to `false`. |

#### Example Request — Single FHIRPath Expression

```bash
curl -X POST http://localhost:9090/fhirpath/get \
  -H "Content-Type: application/json" \
  -d '{
    "fhirResource": {
      "resourceType": "Patient",
      "id": "1",
      "active": true,
      "name": [
        {
          "use": "official",
          "family": "Chalmers",
          "given": ["Peter", "James"]
        }
      ],
      "gender": "male"
    },
    "fhirPath": "Patient.name[0].given[0]"
  }'
```

#### Example Response — Single FHIRPath Expression

```json
{
  "Patient.name[0].given[0]": "Peter"
}
```

#### Example Request — Multiple FHIRPath Expressions

```bash
curl -X POST http://localhost:9090/fhirpath/get \
  -H "Content-Type: application/json" \
  -d '{
    "fhirResource": {
      "resourceType": "Patient",
      "id": "1",
      "active": true,
      "name": [
        {
          "use": "official",
          "family": "Chalmers",
          "given": ["Peter", "James"]
        }
      ],
      "gender": "male"
    },
    "fhirPath": ["Patient.name[0].family", "Patient.gender", "Patient.active"]
  }'
```

#### Example Response — Multiple FHIRPath Expressions

```json
{
  "Patient.name[0].family": "Chalmers",
  "Patient.gender": "male",
  "Patient.active": true
}
```

#### Example Request — With Input Validation

```bash
curl -X POST http://localhost:9090/fhirpath/get \
  -H "Content-Type: application/json" \
  -d '{
    "fhirResource": {
      "resourceType": "Patient",
      "id": "1",
      "active": true,
      "gender": "male"
    },
    "fhirPath": "Patient.gender",
    "validateInputFHIRResource": true
  }'
```

---

### POST /fhirpath/set

Set, update, or remove values in a FHIR resource at a specified FHIRPath location.

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `fhirResource` | `json` | Yes | The FHIR resource to modify. |
| `fhirPath` | `string` | Yes | The FHIRPath expression indicating where to set the value. |
| `value` | `json` | Yes | The value to set. Use `null` to remove a field. |
| `validateInputFHIRResource` | `boolean` | No | Whether to validate the input FHIR resource before modification. Defaults to `false`. |
| `validateOutputFHIRResource` | `boolean` | No | Whether to validate the output FHIR resource after modification. Defaults to `false`. |

#### Example Request — Update a Value

```bash
curl -X POST http://localhost:9090/fhirpath/set \
  -H "Content-Type: application/json" \
  -d '{
    "fhirResource": {
      "resourceType": "Patient",
      "id": "1",
      "active": true,
      "gender": "male"
    },
    "fhirPath": "Patient.active",
    "value": false
  }'
```

#### Example Response — Update a Value

```json
{
  "resourceType": "Patient",
  "id": "1",
  "active": false,
  "gender": "male"
}
```

#### Example Request — Remove a Field

```bash
curl -X POST http://localhost:9090/fhirpath/set \
  -H "Content-Type: application/json" \
  -d '{
    "fhirResource": {
      "resourceType": "Patient",
      "id": "1",
      "active": true,
      "gender": "male"
    },
    "fhirPath": "Patient.gender",
    "value": null
  }'
```

#### Example Request — With Validation

```bash
curl -X POST http://localhost:9090/fhirpath/set \
  -H "Content-Type: application/json" \
  -d '{
    "fhirResource": {
      "resourceType": "Patient",
      "id": "1",
      "active": true
    },
    "fhirPath": "Patient.gender",
    "value": "female",
    "validateInputFHIRResource": true,
    "validateOutputFHIRResource": true
  }'
```

## Error Handling

- **GET endpoint**: If a FHIRPath expression is invalid or evaluation fails, the corresponding key in the response map will contain an `error` field with the error message.

  ```json
  {
    "Patient.invalidPath": {
      "error": "Invalid FHIRPath expression"
    }
  }
  ```

- **SET endpoint**: Returns HTTP `400 Bad Request` with an error message if the operation fails.

  ```json
  {
    "error": "Error message describing the failure"
  }
  ```

## References

- [HL7 FHIRPath Specification](https://hl7.org/fhir/fhirpath.html)
- [ballerinax/health.fhir.r4utils.fhirpath API Docs](https://central.ballerina.io/ballerinax/health.fhir.r4utils.fhirpath)

