# WSO2 CQL Enrichment Engine — REST API

A FHIR Questionnaire → CQL enrichment service that generates EHR-executable CQL pre-population expressions, resolves multi-terminology ValueSets, and produces DTR-ready `$questionnaire-package` bundles.

## Quick Start

```bash
npm install
npm run dev     # Development with auto-reload
npm start       # Production
npm test        # Run test suite (requires server running)
```

Server starts at `http://localhost:3000`.

## API Endpoints

### `GET /api/health`
Health check and capabilities listing.

### `POST /api/enrich`
Full enrichment pipeline. Send a FHIR Questionnaire, get back everything.

```bash
curl -X POST http://localhost:3000/api/enrich \
  -H "Content-Type: application/json" \
  -d @questionnaire.json
```

**Response:**
```json
{
  "success": true,
  "enrichedQuestionnaire": { ... },
  "cqlLibrary": {
    "name": "...",
    "url": "...",
    "cql": "library ... define ...",
    "resource": { "resourceType": "Library", ... }
  },
  "valueSets": [ ... ],
  "questionnairePackageBundle": { "resourceType": "Bundle", ... },
  "stats": {
    "totalItems": 7,
    "highConfidence": 4,
    "mediumConfidence": 2,
    "manual": 1,
    "autoPopulationRate": 86
  }
}
```

### `POST /api/analyze`
Item-level analysis without full CQL generation.

```bash
curl -X POST http://localhost:3000/api/analyze \
  -H "Content-Type: application/fhir+json" \
  -d @questionnaire.json
```

### `POST /api/cql`
CQL Library only. Supports `Accept: text/plain` for raw CQL output.

```bash
# JSON response
curl -X POST http://localhost:3000/api/cql \
  -H "Content-Type: application/fhir+json" \
  -d @questionnaire.json

# Raw CQL text
curl -X POST http://localhost:3000/api/cql \
  -H "Content-Type: application/fhir+json" \
  -H "Accept: text/plain" \
  -d @questionnaire.json
```

### `POST /api/bundle`
`$questionnaire-package` Bundle only. Returns `application/fhir+json`.

```bash
curl -X POST http://localhost:3000/api/bundle \
  -H "Content-Type: application/fhir+json" \
  -d @questionnaire.json
```

### `GET /api/terminology`
Lists supported code systems, FHIR resources, and US Core profiles.

## Architecture

```
┌──────────────────┐     ┌────────────────────┐     ┌──────────────────┐
│ FHIR Questionnaire│────▶│  CQL Enrichment    │────▶│ $questionnaire-  │
│ (any source)      │     │  Engine            │     │ package Bundle   │
└──────────────────┘     │                    │     ├──────────────────┤
                         │ ┌────────────────┐ │     │ - Questionnaire  │
                         │ │ Item Analyzer   │ │     │   (enriched)     │
                         │ │ - Demographics  │ │     │ - CQL Library    │
                         │ │ - Conditions    │ │     │   (base64)       │
                         │ │ - Observations  │ │     │ - ValueSets      │
                         │ │ - Medications   │ │     │   (SNOMED+ICD10) │
                         │ │ - Semantics     │ │     └──────────────────┘
                         │ └────────────────┘ │
                         │ ┌────────────────┐ │
                         │ │ CQL Generator   │ │
                         │ │ - US Core R4    │ │
                         │ │ - FHIRHelpers   │ │
                         │ │ - Condition +   │ │
                         │ │   Observation   │ │
                         │ │   fallback      │ │
                         │ └────────────────┘ │
                         │ ┌────────────────┐ │
                         │ │ ValueSet        │ │
                         │ │ Resolver        │ │
                         │ │ - SNOMED CT     │ │
                         │ │ - ICD-10-CM     │ │
                         │ │ - LOINC         │ │
                         │ │ - RxNorm / CPT  │ │
                         │ └────────────────┘ │
                         └────────────────────┘
```

## Integration with WSO2

This API is designed to sit behind WSO2 API Manager as a managed service:

- **DTR Payer Service**: The `/api/bundle` endpoint produces bundles ready to serve from the `$questionnaire-package` FHIR operation
- **Content Pipeline**: Use `/api/enrich` in a CI/CD pipeline that takes authored Questionnaires and produces production CQL
- **Ballerina Integration**: The engine module (`src/engine.js`) can be ported to Ballerina for native WSO2 platform integration

## CMS-0057-F Compliance

The generated CQL targets US Core FHIR R4 resources required by CMS-0057-F:
- All expressions are EHR-executable via SMART on FHIR / DTR launch context
- Multi-terminology ValueSets ensure cross-EHR compatibility
- Condition + Observation fallback queries maximize data capture
- No payer-side resources (FormularyItem, EOB) are referenced
