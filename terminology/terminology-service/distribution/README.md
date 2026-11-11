# FHIR Terminology Service

A FHIR R4 terminology service (CodeSystem, ValueSet and ConceptMap operations), built with Ballerina.

## Contents

| Path | Description |
| --- | --- |
| `terminology_service.jar` | The service executable. |
| `server.sh` / `server.bat` | Startup scripts. |
| `Config.toml` | Runtime configuration: port, database and logging. |
| `database/terminology.mv.db` | Empty embedded H2 database with the schema already created. |
| `dbscripts/h2.sql`, `dbscripts/postgresql.sql` | Schema scripts. **They drop existing tables before creating new ones.** |

## Prerequisites

- Java 21 or later on `PATH`.

## Run

```sh
./server.sh          # Linux / macOS
server.bat           # Windows
```

The service listens on `http://localhost:9090/fhir/r4`. The first start also loads the built-in FHIR R4 and HL7 Terminology CodeSystems (about 500) into the database, which takes about 15 seconds. To check it is up:

```sh
curl http://localhost:9090/fhir/r4/metadata
```

Pass JVM options through `JAVA_OPTS`. SNOMED CT and ICD-10-CM imports need a larger heap:

```sh
JAVA_OPTS="-Xmx4g" ./server.sh
```

## Database

By default the service uses the bundled H2 database. To use PostgreSQL:

1. Create a database, then initialize it with `psql -d <database> -f dbscripts/postgresql.sql`.
2. In `Config.toml`, set `db_type = "postgresql"` and fill in the `[wso2.terminology_service.store_pg]` section.

## Loading terminology content

```sh
curl -X POST "http://localhost:9090/fhir/r4/%24upload" \
  -H "Content-Type: application/zip" \
  -H "x-terminology-type: FHIR" \
  --data-binary @codesystems.zip
```

`x-terminology-type` must be one of `FHIR`, `LOINC`, `SNOMED` or `ICD10`. The `$` in `$upload` must be sent percent-encoded as `%24upload`.

For the full API reference, see the [project README](https://github.com/wso2/open-healthcare-prebuilt-services/tree/main/terminology/terminology-service).
