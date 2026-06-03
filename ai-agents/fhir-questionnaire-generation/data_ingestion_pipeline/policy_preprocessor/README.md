# Policy Preprocessor Service

A Ballerina service that preprocesses payer policy documents for FHIR questionnaire generation. It orchestrates PDF-to-Markdown conversion, policy chunking, job tracking, callback handling, and optional FHIR server publishing.

---

## Core Features

- **Async Orchestration**: Starts end-to-end processing and continues in background after notifications.
- **PDF Intake**: Accepts one or more PDF files in a multipart request.
- **Document Chunking**: Splits policy markdown into structured chunks for downstream generation.
- **Job Tracking APIs**: Exposes endpoints to query job status, bundles, and failed scenarios.
- **Storage Flexibility**: Supports both local storage and FTP-backed storage.
- **FHIR Publishing (Optional)**: Posts generated `ValueSet`, `Library`, and `Questionnaire` resources to a configured FHIR server.

---

## Quick Start

### Prerequisites

- Ballerina (Swan Lake)
- Running dependent services:
  - PDF-to-Markdown service (default: `http://localhost:8000`)
  - FHIR questionnaire orchestration service (default: `http://localhost:6060/generate`)
      - Check the FHIR questionnaire generation README for setup instructions.
- (Optional) Running FHIR server for resource posting.

### Setup & Run

1. **Navigate to the service directory**:

	```bash
	cd fhir-questionnaire-generation-pipeline/data_ingestion_pipeline/policy_preprocessor
	```

2. **Set environment variables** (minimum required):

	```bash
	export ANTHROPIC_API_KEY="<your_api_key>"
	```

3. **Create local data directories** (if `STORAGE_TYPE=local`):

	```bash
	mkdir -p ../../data/pdf ../../data/md ../../data/chunks
	```

4. **Run the service**:

	```bash
	bal run
	```

The API is available at `http://localhost:6080` by default.

---

## API Overview

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET`  | `/health` | Checks if the service is operational. |
| `POST` | `/convert` | Uploads one or more PDF files and starts processing. |
| `POST` | `/notification` | Receives async status notifications from conversion/generation services. |
| `POST` | `/reTrigger` | Re-triggers processing for an existing `file_name` + `job_id`. |
| `POST` | `/questionnaires` | Receives generated questionnaire bundle and failed scenario metadata. |
| `GET`  | `/questionnaires` | Returns all stored bundles, or a single bundle with query params. |
| `GET`  | `/failedScenarios` | Returns failed scenarios for `file_name` and `job_id`. |
| `GET`  | `/jobStatus` | Returns job metadata/status for `file_name` and `job_id`. |

### Usage Notes

- **Convert**: send multipart files with part name `file` to `/convert`.
- **Single bundle fetch**: `/questionnaires?file_name={file_name}&job_id={job_id}`.
- **Job status**: `/jobStatus?file_name={file_name}&job_id={job_id}`.
- `file_name` is tracked without the `.pdf` extension in job metadata.

---

## Configuration

Set the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | API key used for ToC extraction with Anthropic model. | _required_ |
| `SERVICE_PORT` | HTTP listener port for this service. | `6080` |
| `MAX_CHUNK_SIZE` | Max chunk size used in recursive splitting. | `4500` |
| `PDF_TO_MD_SERVICE_URL` | Base URL of PDF-to-Markdown service. | `http://localhost:8000` |
| `FHIR_QUESTIONNAIRE_SERVICE_URL` | URL for questionnaire generation trigger endpoint. | `http://localhost:6060/generate` |
| `FHIR_SERVER_URL` | FHIR server base URL for optional resource posting. | `""` |
| `STORAGE_TYPE` | Storage backend (`local` or `ftp`). | `local` |
| `LOCAL_STORAGE_PATH` | Base path for local storage. | `../../data` |
| `FTP_HOST` | FTP host (used when `STORAGE_TYPE=ftp`). | `""` |
| `FTP_PORT` | FTP port (used when `STORAGE_TYPE=ftp`). | `2121` |
| `FTP_USERNAME` | FTP username (used when `STORAGE_TYPE=ftp`). | `""` |
| `FTP_PASSWORD` | FTP password (used when `STORAGE_TYPE=ftp`). | `""` |

---

## Workflow Architecture

1. **Upload**: Client sends PDF files to `/convert`.
2. **Store & Trigger**: Service stores PDFs and requests batch conversion from PDF-to-Markdown service.
3. **Notify**: Converter calls `/notification` with completion/failure status.
4. **Preprocess**: Service reads markdown, extracts/uses section titles, and writes chunks (`/chunks/{file}.json`).
5. **Generate**: Service triggers questionnaire generation endpoint.
6. **Receive Bundle**: Generator calls `/questionnaires` with bundle + failed scenarios.
7. **Finalize**:
	- In-memory stores are updated.
	- Job status moves through processing states to `COMPLETED` or `failed`.
	- If `FHIR_SERVER_URL` is set, resources are posted in order: `ValueSet` → `Library` → `Questionnaire`.
