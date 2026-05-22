# Test Suite — open-healthcare-fhir-server-go

## Quick start

```bash
cd miscellaneous/fhir-server-go
go test ./...         # run all tests
go test ./... -v      # verbose (shows each test name)
go test ./... -race   # data race detector
```

All 107 tests are **unit tests** — no database, no Docker, no network (ig cache-miss tests spin up an `httptest.Server` locally). They run in under 5 seconds on a laptop.

---

## Coverage summary

| Package | Tests | What is covered |
|---|---|---|
| `internal/fhirpath` | 20 | FHIRPath evaluator — path traversal, array flattening, union (`\|`), `where()`, `extension()`, `ofType()`, `EvaluatePolymorphic` |
| `internal/searchparam` | 10 | Registry `Upsert` / `Lookup` / `ForResource` / `Remove`, overwrite semantics, concurrent access |
| `internal/store` | 24 | `mergePatch` (RFC 7396), `setMeta`, `unmarshalWithMeta`, date-range expansion, `splitModifier`, `extractComparatorPrefix`, `looksLikeDate/Number`, `NotFoundError` |
| `internal/ig` | 17 | `parseSpec`, `parsePackage` (synthetic .tgz), disk-cache hit/miss/write, explicit URL fetch, HTTP 404, registry URL path |
| `internal/config` | 14 | All env vars, defaults, `DATABASE_URL` vs component vars, `SERVER_PORT` validation, `IG_PACKAGES` comma-splitting, `BASE_URL` default includes port |
| `internal/handler` | 22 | All REST endpoints (read, vread, create, update, patch, delete, search, history, $everything, metadata), health probes, FHIR content-type, error shapes |
| **Total** | **107** | **0 failures** |

---

## Packages without tests (require a live DB)

| Package | Why |
|---|---|
| `internal/db` | Schema migration — needs PostgreSQL |
| `internal/index` | `Extractor.Index` / `Delete` insert into sp_* tables |
| `internal/seed` | `SeedSearchParams` bulk-inserts CSV into DB |
| `internal/store` (CRUD path) | `Create`, `Read`, `Update`, `Delete`, `Search`, `GetHistory` all need pgxpool |
| `cmd/server` | Full integration — needs DB + HTTP server |

These are best covered with `docker compose up db` and integration tests (or testcontainers). The pure-logic helpers inside `store` (25 functions) **are** tested via `internal/store/helpers_test.go`.

---

## Bugs found and fixed by tests

Writing the test suite revealed **4 pre-existing bugs** in production code:

### 1. FHIRPath evaluator — nodes not chained (`internal/fhirpath`)

**Symptom**: `Patient.name.family` returned the whole name object instead of the family string.

**Root cause**: `Evaluate()` applied every AST node independently against the original resource (union of individual lookups) instead of chaining them (output of node N is input to node N+1). Only single-token paths like `Patient.id` worked correctly.

**Impact**: All multi-level search params (e.g., `Patient.name.family`, `Observation.code.coding.code`) were incorrectly indexed. Search by `name`, `code`, etc., would not match.

**Fix**: `Evaluate()` now iterates chains; `parse()` returns `[][]node` (one chain per union alternative) rather than a flat `[]node`.

---

### 2. Polymorphic field expansion — type name not title-cased (`internal/fhirpath`)

**Symptom**: `Observation.value.ofType(Quantity)` expanded to `"valueQuantity"` (correct by coincidence — 'Q' is already upper). But `Condition.onset.ofType(dateTime)` expanded to `"onsetdateTime"` (lowercase 'd') instead of `"onsetDateTime"`.

**Root cause**: `expandPolymorphic` concatenated `field + typeName` directly. In FHIR's camelCase convention the type's first letter must be uppercased when it follows a field name.

**Fix**: `concreteField = field + strings.ToUpper(typeName[:1]) + typeName[1:]`

---

### 3. `where()` not-equal operator parsed incorrectly (`internal/fhirpath`)

**Symptom**: `Patient.name.where(use!='official')` matched zero names instead of filtering to non-official names.

**Root cause**: `parseWhere` iterated separators in order `["=", "!="]`. `strings.Index("use!='official'", "=")` found the `=` inside `!=` at position 4, producing key `"use!"` instead of `"use"`, and operator `"="` instead of `"!="`. The key `"use!"` never matches any field.

**Fix**: Reordered to `["!=", "="]` — longer operator checked first.

---

### 4. IG fetcher treated HTTP URLs ending in `.tgz` as local file paths (`internal/ig`)

**Symptom**: `fetchPackage("https://host/pkg.tgz", ...)` called `os.ReadFile("https://host/pkg.tgz")` and returned a "no such file or directory" error.

**Root cause**: The local-file guard `strings.HasSuffix(spec, ".tgz")` ran before the HTTP URL guard `strings.HasPrefix(spec, "http://")`, so any URL ending in `.tgz` (the most common case for FHIR package registries) was mistaken for a filesystem path.

**Fix**: HTTP/HTTPS prefix check moved first; shared download+cache logic extracted to `fetchURL()`.

---

## Test architecture notes

### No DB required
All tests are pure unit tests. Handler tests use a `mockStore` that implements the `handler.StoreAPI` interface introduced for this purpose. The `StoreAPI` interface is also what `NewRouter` now accepts, making the production `*store.Store` injectable without code changes elsewhere.

### `httptest.Server` for IG download tests
`TestFetchPackage_CacheMiss_WritesCache`, `TestFetchPackage_ExplicitURL`, `TestFetchPackage_HTTP404_Error`, and `TestFetchPackage_RegistryLookup` spin up a local HTTP server to test the download path without hitting the real `packages.fhir.org`.

### Synthetic `.tgz` in IG parser tests
`buildTestTgz()` builds a valid gzipped tar in-memory, used by `TestParsePackage_*` tests to verify correct extraction of `SearchParameter` and `StructureDefinition` resources without any real IG files on disk.

### Thread-safety test
`TestRegistry_ConcurrentAccess` fires 50 concurrent read + write goroutines against the same registry to verify the `sync.RWMutex` is correctly applied.

---

## Running a subset

```bash
# One package
go test ./internal/fhirpath/ -v

# One test by name
go test ./... -run TestEvaluate_Where_Match

# All handler tests
go test ./internal/handler/ -v

# With race detector (recommended in CI)
go test ./... -race -count=1
```
