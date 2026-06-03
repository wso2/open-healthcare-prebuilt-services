# FHIR Questionnaire Generation Pipeline

An AI-powered pipeline that ingests healthcare policy PDFs and produces CMS-0057-F compliant FHIR Questionnaire resources enriched with CQL for EHR pre-population via DTR (Documentation Templates and Rules).

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Data Flow](#data-flow)
- [Prerequisites](#prerequisites)
- [Quick Start (Docker)](#quick-start-docker)
- [Local Development](#local-development)
- [Agents (Deployed Separately)](#agents-deployed-separately)
  - [Running the agents](#running-the-agents)
  - [Connecting the agents to the pipeline](#connecting-the-agents-to-the-pipeline)
- [Configuration](#configuration)
- [API Reference](#api-reference)
  - [Policy Preprocessor (port 6080)](#policy-preprocessor-port-6080)
  - [Example: End-to-End Request](#example-end-to-end-request)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Standards Compliance](#standards-compliance)

---

## Overview

The pipeline takes raw coverage policy documents as input and outputs structured FHIR R4 Questionnaire bundles that are ready for integration with EHR systems. Processing is fully automated: upload a PDF, and the system handles conversion, chunking, AI-driven generation, quality review, CQL enrichment, and optional posting to a FHIR server.

<img width="984" height="305" alt="image" src="https://github.com/user-attachments/assets/dba2bec4-4749-4a5b-bb27-bf13b860e052" />

---

## Architecture

The system is split into two parts:

**Docker container** — four services that handle the core pipeline:

| Service | Port | Tech | Role |
|---|---|---|---|
| Policy Preprocessor | 6080 | Ballerina | Primary API — file ingestion, chunking, orchestration |
| Questionnaire Orchestration | 6060 | Ballerina | Generation/review workflow |
| PDF-to-Markdown Service | 8000 | Python / FastAPI | PDF → Markdown conversion |
| CQL Enrichment API | 3000 | Node.js / Express | CQL generation and DTR bundle assembly |

Only port 6080 is exposed externally; all other communication is over localhost.

**Agents (deployed separately)** — two Ballerina AI agent services that must be run and reachable independently:

| Agent | Default Port | Role |
|---|---|---|
| Generator Agent | 7082 | Produces FHIR Questionnaire JSON from coverage policy text |
| Reviewer Agent | 7081 | Validates questionnaires and provides structured feedback |

The Questionnaire Orchestration service calls these agents over HTTP. Their URLs are configured via environment variables (see [Configuration](#configuration)).

---

## Data Flow

1. **Ingest** — Client uploads a policy PDF to the Policy Preprocessor (`POST /convert`).
2. **Convert** — The PDF-to-Markdown Service converts the PDF asynchronously and notifies the Policy Preprocessor on completion.
3. **Chunk** — The Policy Preprocessor extracts the table of contents using an LLM, splits the document into sections (Coverage Rationale, Applicable Codes, supplementary), and stores the chunk store on disk.
4. **Generate & Review** — The Questionnaire Orchestration service runs an iterative loop (up to `AGENT_CONV_LIMIT` rounds):
   - Generator Agent produces a FHIR Questionnaire JSON.
   - Questionnaire is validated against the FHIR R4 schema.
   - Reviewer Agent provides structured feedback (critical / error / warning).
   - If issues remain, a revision prompt is fed back to the generator.
   - Loop exits when the questionnaire is approved or the iteration limit is reached.
5. **Enrich** — The approved questionnaire is sent to the CQL Enrichment API, which:
   - Maps each item to a FHIR resource type and generates EHR-executable CQL expressions.
   - Creates multi-terminology ValueSets (SNOMED CT, ICD-10-CM, LOINC, RxNorm, CPT).
   - Assembles a `$questionnaire-package` Bundle (DTR-ready).
6. **Store & Post** — The enriched bundle is stored by the Policy Preprocessor and optionally posted to a FHIR server.

---

## Prerequisites

- **Docker** and **Docker Compose** (for containerised deployment)
- **Anthropic API key** with access to Claude
- Or for local development: Ballerina 2201.12.10, Python 3.12, Node.js 20

---

## Quick Start (Docker)

> **Note:** The Docker container does **not** include the AI agents. Before starting the container, deploy the [Generator Agent](#agents-deployed-separately) and [Reviewer Agent](#agents-deployed-separately) separately and set their URLs in `.env`.

```bash
# 1. Copy and configure environment
cp .env.example .env
# Edit .env — set ANTHROPIC_API_KEY, FHIR_QUESTIONNAIRE_GENERATOR_URL, and FHIR_REVIEWER_URL

# 2. Build and start
docker-compose up --build

# 3. Verify the service is healthy
curl http://localhost:6080/health
```

The pipeline is now accessible at `http://localhost:6080`.

---

## Local Development

```bash
# First time only — make the script executable
chmod +x start-services.sh

# Start all four services (loads .env automatically)
./start-services.sh

# Stop with Ctrl+C
```

Each service runs in the background. Logs from all services are printed to the same terminal.

---

## Agents (Deployed Separately)

The two AI agents in [`fhir_questionnaire_generation/fhir_questionnaire_agents/`](fhir_questionnaire_generation/fhir_questionnaire_agents/) are **not included in the Docker image**. They must be started independently (e.g. on separate hosts or as separate containers) and their URLs provided to the pipeline via environment variables.

### Running the agents

Each agent is a Ballerina service. Run them from their respective directories:

```bash
# Generator Agent (port 7082)
cd fhir_questionnaire_generation/fhir_questionnaire_agents/fhir_questionnaire_generator_agent
bal run

# Reviewer Agent (port 7081)
cd fhir_questionnaire_generation/fhir_questionnaire_agents/fhir_questionnaire_reviewer_agent
bal run
```

Once running, the endpoints are:
- Generator: `http://<host>:7082/QuestionnaireGenerator`
- Reviewer: `http://<host>:7081/Reviewer`

### Connecting the agents to the pipeline

Set the following variables in `.env` (or pass them to `docker-compose`) so the Questionnaire Orchestration service can reach the agents:

```ini
FHIR_QUESTIONNAIRE_GENERATOR_URL=http://<generator-host>:7082/QuestionnaireGenerator
FHIR_REVIEWER_URL=http://<reviewer-host>:7081/Reviewer
```

---

## Configuration

Copy `.env.example` to `.env` and set values as needed.

| Variable | Required | Default | Description |
|---|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | — | Anthropic API key |
| `EXPOSED_PORT` | No | `6080` | Host port for the Policy Preprocessor |
| `ANTHROPIC_GENERATOR_AGENT_AI_GATEWAY_URL` | No | `https://api.anthropic.com/v1` | Anthropic API gateway for generator |
| `ANTHROPIC_REVIEWER_AGENT_AI_GATEWAY_URL` | No | `https://api.anthropic.com/v1` | Anthropic API gateway for reviewer |
| `AGENT_CONV_LIMIT` | No | `5` | Maximum generation-review iterations |
| `FHIR_QUESTIONNAIRE_GENERATOR_URL` | Yes | — | URL of the Generator Agent (e.g. `http://<host>:7082/QuestionnaireGenerator`) |
| `FHIR_REVIEWER_URL` | Yes | — | URL of the Reviewer Agent (e.g. `http://<host>:7081/Reviewer`) |
| `FHIR_SERVER_URL` | No | `http://localhost:9090/fhir/r4` | FHIR server to post completed bundles to |

---

## API Reference

All client interaction goes through the **Policy Preprocessor** at port 6080. See [`main_openapi.yaml`](main_openapi.yaml) for the full OpenAPI specification.

### Policy Preprocessor (port 6080)

| Method | Path | Description |
|---|---|---|
| `POST` | `/convert` | Upload a policy PDF (multipart/form-data) to begin processing |
| `GET` | `/jobStatus` | Poll job progress (`?file_name=&job_id=`) |
| `GET` | `/questionnaires` | Retrieve generated FHIR bundles |
| `GET` | `/failedScenarios` | List jobs that encountered errors |
| `POST` | `/reTrigger` | Retry a failed job |
| `GET` | `/health` | Health check |

### Example: End-to-End Request

```bash
# 1. Upload a PDF
curl -X POST http://localhost:6080/convert \
  -F "file=@policy.pdf"

# 2. Poll until status is COMPLETED
curl "http://localhost:6080/jobStatus?file_name=policy&job_id=<job_id>"

# 3. Retrieve the generated bundle
curl http://localhost:6080/questionnaires
```

---

## Project Structure

```
.
├── Dockerfile                          # Multi-stage build (Ballerina + Python + Node.js)
├── docker-compose.yml
├── entrypoint.sh                       # Container startup script
├── start-services.sh                   # Local development startup script
├── main_openapi.yaml                   # OpenAPI spec for the Policy Preprocessor
├── .env.example
│
├── data/                               # Runtime data (mounted as a volume)
│   ├── pdf/                            # Uploaded PDFs
│   ├── md/                             # Converted Markdown files
│   └── chunks/                         # JSON chunk stores
│
├── data_ingestion_pipeline/
│   ├── pdf_to_md_service/              # FastAPI service — PDF conversion (port 8000)
│   └── policy_preprocessor/            # Ballerina service — ingestion & orchestration (port 6080)
│
└── fhir_questionnaire_generation/
    ├── fhir_questionnaire_agents/
    │   ├── fhir_questionnaire_generator_agent/   # Generator AI agent (port 7082)
    │   └── fhir_questionnaire_reviewer_agent/    # Reviewer AI agent (port 7081)
    ├── fhir_questionnaire_orchestration/          # Generation workflow (port 6060)
    └── cql-enrichment-api/                        # CQL + DTR bundle generation (port 3000)
```

Each subdirectory contains its own `README.md` with service-specific documentation.

---

## Technology Stack

| Component | Technology |
|---|---|
| PDF conversion | Python 3.12, FastAPI, pymupdf4llm |
| Policy preprocessor & orchestration | Ballerina 2201.12.10 |
| AI generation & review | Anthropic Claude (claude-sonnet-4-20250514) |
| CQL enrichment | Node.js 20, Express.js |
| FHIR standard | FHIR R4 (ballerinax/health.fhir.r4) |
| Containerisation | Docker, Java 21 (Eclipse Temurin) |
| Clinical terminology | SNOMED CT, ICD-10-CM, LOINC, RxNorm, CPT |
