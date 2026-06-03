# PDF to Markdown Conversion Service

A FastAPI microservice for converting PDF documents to Markdown using [**pymupdf4llm**](https://github.com/pymupdf/pymupdf4llm). It operates asynchronously, supports batch processing, and integrates with both FTP and local file storage.

---

## Core Features

- **Asynchronous & Batch Processing**: Handles single or multiple file conversions in the background using FastAPI's `BackgroundTasks`.
- **Flexible Storage**: Supports both FTP and local file systems for reading PDFs and storing Markdown files.
- **Webhook Notifications**: Notifies downstream services via HTTP callback upon completion of a conversion.
- **Health Check**: Includes a `/health` endpoint for service monitoring.
- **Validated Requests**: Ensures data integrity with Pydantic-based validation.

---

## Quick Start

### Prerequisites

- Python 3.12.4
- [uv](https://github.com/astral-sh/uv) (for package management)

### Setup & Run

Only follow these steps if you want to run the service locally. If you are running the entire pipeline using Docker, this service will be started as part of the `docker-compose` setup and you can skip these steps.

1.  **Navigate to the Service Directory**:
    ```bash
    cd fhir-questionnaire-generation-pipeline/data_ingestion_pipeline/pdf_to_md_service
    ```

2.  **Configure Environment**:
    Create a `.env` file (you can copy `.env.example`) and configure your storage and notification settings.
    ```bash
    cp .env.example .env
    # Edit .env with your settings
    ```

3.  **Install Dependencies**:
    ```bash
    uv sync
    ```

4.  **Create Local Directories** (if not using FTP):
    ```bash
    mkdir -p ../../data/pdf ../../data/md
    ```

5.  **Run the Service**:
    ```bash
    uv run main:app --host 0.0.0.0 --port 8000 --reload
    ```

The API is now available at `http://0.0.0.0:8000`.

---

## API Overview

### Endpoints

| Method | Endpoint         | Description                                  |
|--------|------------------|----------------------------------------------|
| `POST` | `/convert`       | Submits a single PDF for conversion.         |
| `POST` | `/batch-convert` | Submits a batch of PDFs for conversion.      |
| `GET`  | `/health`        | Checks if the service is operational.        |

### Usage

-   **Single Conversion**: `POST` to `/convert` with `{"job_id": "...", "file_name": "..."}`.
-   **Batch Conversion**: `POST` to `/batch-convert` with `{"requests": [{"job_id": "...", "file_name": "..."}, ...]}`.

**Note**: Provide `file_name` without the `.pdf` extension. PDFs are sourced from the `/pdf` directory and Markdown files are saved to the `/md` directory in your configured storage.

---

## Configuration

Set the following environment variables in your `.env` file:

| Variable                  | Description                                             | Default                                |
|---------------------------|---------------------------------------------------------|----------------------------------------|
| `USE_FTP`                 | `true` for FTP, `false` for local storage.              | `false`                                |
| `FTP_HOST`                | FTP server hostname.                                    | `127.0.0.1`                            |
| `FTP_PORT`                | FTP server port.                                        | `2121`                                 |
| `FTP_USERNAME`            | FTP username.                                           | `ftp_user`                             |
| `FTP_PASSWORD`            | FTP password.                                           | `ftp_password`                         |
| `LOCAL_DIR`               | Path to the local data directory.                       | `../../data/`                          |
| `NOTIFICATION_CALLBACK_URL`| URL to send completion notifications to.                | `http://localhost:6080/notification`   |

---

## Workflow Architecture

1.  **Request**: A client sends a `POST` request to `/convert` or `/batch-convert`.
2.  **Queue**: The service validates the request and queues the conversion as a background task, immediately returning a `202 Accepted` response.
3.  **Process**: The background task reads the PDF, converts it to Markdown, and saves the output to the configured storage.
4.  **Notify**: A final notification is sent to the configured `NOTIFICATION_CALLBACK_URL` with the job's outcome (`completed` or `failed`).
