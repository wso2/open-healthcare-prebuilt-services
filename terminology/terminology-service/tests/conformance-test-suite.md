# Running the HL7 Terminology Ecosystem Conformance Suite

This guide explains how to run the **HL7 Terminology Ecosystem Conformance Suite** against the local terminology service and inspect the test results.

## Prerequisites

Before running the suite, make sure you have:

- A working installation of **Ballerina**.
- **Java** installed and available on your `PATH`.
- The `terminology/terminology-service` configured with either **H2** or **PostgreSQL**.
- The HL7 Terminology Ecosystem test package installed locally.

---

## 1. Download the validator

The conformance suite is run using the HL7 FHIR validator CLI.

Download **`validator_cli.jar` version `6.10.4`**:

- **Direct download:** https://github.com/hapifhir/org.hl7.fhir.core/releases/download/6.10.4/validator_cli.jar
- **Other versions:** https://github.com/hapifhir/org.hl7.fhir.core/releases

> **Note:** A newer validator version may also work, but version `6.10.4` is recommended for consistent results.

You can place `validator_cli.jar` anywhere convenient. The commands below assume it is in your current working directory.

---

## 2. Start the terminology service

The conformance suite requires a running instance of the terminology service.

The service is located at:

```text
terminology/terminology-service
````

Configure `Config.toml` to use either **H2** or **PostgreSQL**. See the main [README](../README.md#supported-db-types-and-configurations) for database configuration details.

> **Important:** The `simple-cases` suite does **not** require SNOMED CT or LOINC data to be loaded. It only requires the small CodeSystem and ValueSet fixtures loaded in the next step.

Start the service:

```sh
cd terminology/terminology-service
bal run
```

The service should be available at:

```text
http://localhost:9090
```

---

## 3. Load the test fixtures

The `simple-cases` suite requires a small set of CodeSystem and ValueSet resources.

These resources are loaded from the HL7 Terminology Ecosystem test package (`hl7.fhir.uv.tx-ecosystem#1.9.3`), cached locally under `~/.fhir/packages` (`%USERPROFILE%\.fhir\packages` on Windows).

> **First time only:** If the HL7 Terminology Ecosystem package isn't cached yet, the `$T` paths below may point to files that don't exist. The validator downloads and caches the package automatically when you run Step 4 for the first time.
>
> **So, on the first run only:**
>
> 1. Skip to **Step 4** and run the command once. It's okay if the tests fail because the required fixtures haven't been loaded yet.
> 2. Once the package has been downloaded and cached, return to **Step 3** and load the test fixtures.
> 3. Then go back to **Step 4** and run the conformance suite again.
>
> On subsequent runs, you can start from **Step 3**.

> **Important:** `POST /CodeSystem` and `POST /ValueSet` reject resources when a resource with the same `url` + `version` already exists (`400` response).
>
> Therefore, **run this setup only once per database**.

### Windows — PowerShell

```powershell
$T = "$env:USERPROFILE\.fhir\packages\hl7.fhir.uv.tx-ecosystem#1.9.3\package\tests"

curl.exe -X POST "http://localhost:9090/fhir/r4/CodeSystem" -H "Content-Type: application/fhir+json" --data-binary "@$T\simple\codesystem-simple.json"
foreach ($f in "valueset-all","valueset-active","valueset-inactive","valueset-enumerated","valueset-enumerated-bad","valueset-filter-isa","valueset-filter-child-of","valueset-filter-property","valueset-filter-regex","valueset-filter-regex2","valueset-filter-regex-prop") {
  curl.exe -X POST "http://localhost:9090/fhir/r4/ValueSet" -H "Content-Type: application/fhir+json" --data-binary "@$T\simple\$f.json"
}
```

### Linux / macOS — Bash

```bash
T="$HOME/.fhir/packages/hl7.fhir.uv.tx-ecosystem#1.9.3/package/tests"

curl -X POST "http://localhost:9090/fhir/r4/CodeSystem" -H "Content-Type: application/fhir+json" --data-binary "@$T/simple/codesystem-simple.json"
for f in valueset-all valueset-active valueset-inactive valueset-enumerated valueset-enumerated-bad valueset-filter-isa valueset-filter-child-of valueset-filter-property valueset-filter-regex valueset-filter-regex2 valueset-filter-regex-prop; do
  curl -X POST "http://localhost:9090/fhir/r4/ValueSet" -H "Content-Type: application/fhir+json" --data-binary "@$T/simple/$f.json"
done
```

> **Known failure:** the `valueset-filter-child-of` POST above returns `400`. Its `compose.include.filter.op` value is `"child-of"`, which is an **R5-only** filter operator (added in R5's `filter-operator` ValueSet; R4 only has 9 operators, not the 11 in R5). This is expected and doesn't block the other 11 fixtures from loading. `simple-expand-child-of` will fail the same way (`400` instead of `2xx`) for the same reason - implementing `child-of` support is out of scope for this R4 service.

---

## 4. Run the conformance suite

Run the validator from the directory containing `validator_cli.jar`:

```sh
java -jar validator_cli.jar txTests -tx=http://localhost:9090/fhir/r4 -test-version=1.9.3 -suite=simple-cases -output=./results
```

### Command options

| Option          | Description                                       |
| --------------- | ------------------------------------------------- |
| `txTests`       | Runs the terminology server conformance tests.    |
| `-tx`           | URL of the terminology service being tested.      |
| `-test-version` | Version of the **conformance test suite** to run. |
| `-suite`        | Test suite to execute.                            |
| `-output`       | Directory where detailed test results are stored. |

> **Note:** `-test-version` refers to the **version of the test suite**, not the FHIR version.

If `-test-version` is omitted, the validator uses `current`, which tracks the suite's master version and may change over time.

For reproducible results, it is recommended to keep the version pinned to `1.9.3`.

---

## 5. Check the results

While the suite is running, the console shows the status of each test case.

For example:

```text
Testing simple-expand-child-of:

   -- simple-expand-child-of: Fail (00:00:00.127)

    Response Code fail: should be '2xx' but is '400'
```

This usually gives enough information to identify which tests failed and why.

### Detailed results

The output directory (`./results`) contains additional information:

```text
results/
├── test.log
├── actual/
└── expected/
```

| File / Directory | Description                                               |
| ---------------- | --------------------------------------------------------- |
| `test.log`       | Complete copy of the console output from the test run.    |
| `actual/`        | The actual responses returned by the terminology service. |
| `expected/`      | The expected responses provided by the conformance suite. |

### Investigating a failure

For a failing test:

1. Find the corresponding response file in `actual/`.
2. Find the matching expected response in `expected/`.
3. Compare the two files.

You can use any diff/compare tool, such as:

- `diff`
- VS Code's **Compare** feature
- WinMerge
- Beyond Compare

