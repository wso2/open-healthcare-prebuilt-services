# FHIR Questionnaire Generation

A multi-service pipeline that generates FHIR R4 Questionnaire artifacts from preprocessed policy chunks using AI agents, validates/reviews them, enriches them with CQL, and posts the final bundle back to the policy preprocessor.

---

## Core Features

- **Agent Collaboration Loop**: Generator and Reviewer agents iterate until approved (or conversation limit reached).
- **FHIR Validation**: Generated Questionnaire JSON is structurally validated against FHIR R4.
- **Applicable Code Appending**: HCPCS, CPT, and ICD-10 options are extracted and appended as `choice` items.
- **CQL Enrichment**: Integrates with the CQL Enrichment API to produce a questionnaire-package bundle.
- **Async Orchestration API**: Orchestration service accepts requests and processes them in background.
- **Policy Preprocessor Integration**: Sends notifications and final bundle to policy preprocessor endpoints.

---

## Components

- **Orchestration Service** (`fhir_questionnaire_orchestration`)
   - Base URL: `http://localhost:6060`
   - Endpoints: `GET /health`, `POST /generate`

- **Generator Agent** (`fhir_questionnaire_agents/fhir_questionnaire_generator_agent`)
   - Base URL: `http://localhost:7082/QuestionnaireGenerator`
   - Endpoint: `POST /chat`

- **Reviewer Agent** (`fhir_questionnaire_agents/fhir_questionnaire_reviewer_agent`)
   - Base URL: `http://localhost:7081/Reviewer`
   - Endpoint: `POST /chat`

- **CQL Enrichment API** (`cql-enrichment-api`)
   - Base URL: `http://localhost:3000`
   - Used endpoint: `POST /api/enrich`

---

## Quick Start

Only follow these steps if you want to run the service locally. If you are running the entire pipeline using Docker, this service will be started as part of the `docker-compose` setup and you can skip these steps.

### Prerequisites

- Ballerina (Swan Lake)
- Node.js (for `cql-enrichment-api`)
- Running Policy Preprocessor service (default: `http://localhost:6080`)

### 1. Start Generator Agent

Configure the `ANTHROPIC_API_KEY` environment variable in `Config.toml` before starting the service.

```bash
cd fhir_questionnaire_generation/fhir_questionnaire_agents/fhir_questionnaire_generator_agent
bal run
```

### 2. Start Reviewer Agent

Configure the `ANTHROPIC_API_KEY` environment variable in `Config.toml` before starting the service.
```bash
cd fhir_questionnaire_generation/fhir_questionnaire_agents/fhir_questionnaire_reviewer_agent
bal run
```

### 3. Start CQL Enrichment API

```bash
cd fhir_questionnaire_generation/cql-enrichment-api
npm install
npm start
```

### 4. Start Orchestration Service

```bash
cd fhir_questionnaire_generation/fhir_questionnaire_orchestration
export ANTHROPIC_API_KEY="<your_api_key>"
bal run
```

The orchestration API is available at `http://localhost:6060`.

---

## API Overview (Orchestration)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET`  | `/health` | Checks if the orchestration service is healthy. |
| `POST` | `/generate` | Starts questionnaire generation for a file/job. Returns `202 Accepted`. |

### Request Example (`POST /generate`)

```json
{
   "file_name": "medical_policy_001",
   "job_id": "job-medical_policy_001"
}
```

---

## Configuration (Orchestration)

Set the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVICE_PORT` | Orchestration service port. | `6060` |
| `POLICY_FLOW_ORCHESTRATOR` | Policy preprocessor base URL for `/notification` and `/questionnaires`. | `http://localhost:6080` |
| `FHIR_QUESTIONNAIRE_GENERATOR_URL` | Generator agent base URL. | `http://localhost:7082/QuestionnaireGenerator` |
| `FHIR_REVIEWER_URL` | Reviewer agent base URL. | `http://localhost:7081/Reviewer` |
| `CQL_ENRICHMENT_API_URL` | CQL enrichment API base URL. | `http://localhost:3000` |
| `AGENT_CONV_LIMIT` | Max reviewer/generator iterations. | `5` |
| `ANTHROPIC_API_KEY` | Anthropic API key (required). | _required_ |
| `ANTHROPIC_GENERATOR_AGENT_AI_GATEWAY_URL` | Anthropic gateway URL used by orchestration-side LLM calls. | `https://api.anthropic.com/v1` |
| `STORAGE_TYPE` | Storage backend hint (`local`/`ftp`). | `local` |
| `LOCAL_STORAGE_PATH` | Base path used to read chunk files. | `../../data` |

---

## End-to-End Workflow

1. Policy preprocessor calls orchestration `POST /generate`.
2. Orchestration loads chunk file from `/chunks/{file_name}.json`.
3. Coverage rationale is sent to Generator agent.
4. Reviewer agent evaluates output; orchestration enforces iterative correction.
5. Final questionnaire is validated and applicable codes are appended.
6. Questionnaire is enriched through CQL API (`/api/enrich`) to produce a FHIR bundle.
7. Orchestration notifies policy preprocessor and posts final payload to `POST /questionnaires`.
