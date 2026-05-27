# PDF to MD Service

The **PDF to MD Service** is a lightweight microservice designed to convert **PDF documents** into **Markdown (MD)** format.
Built using [**Docling**](https://docling-project.github.io/docling/), it exposes RESTful API endpoints to process PDF files, convert them to Markdown, and automatically upload the converted files to an **FTP server** for downstream processing.
Converted files are stored in the `/md` directory on the FTP server.

---

## Exposed Endpoints

| Method   | Endpoint   | Description                                                               |
| -------- | ---------- | ------------------------------------------------------------------------- |
| **POST** | `/convert` | Converts a PDF file to Markdown and uploads the result to the FTP server. |
| **GET**  | `/health`  | Health check endpoint to verify the service is running properly.          |

---

## Configuration

The service behavior can be customized using the following **environment variables**:
* **FTP Server Settings**: Host, port, username, and password for connecting to the FTP server.
* **Notification URL**: Endpoint URL to send a notification once the PDF-to-Markdown conversion is complete.


```sh
FTP_HOST=""
FTP_PORT=21
FTP_USER=""
FTP_PASSWORD=""

NOTIFICATION_URL=""
```

---

## Setup Instructions

1. **Clone** the repository:

   ```bash
   git clone <repository_url>
   ```

2. **Navigate** to the project directory:

   ```bash
   cd pdf_to_md_service
   ```

3. **Install** dependencies:

   ```bash
   uv sync
   ```

4. **Run** the service:

   ```bash
   uv run main.py
   ```

5. The service will be available at:
   **`http://0.0.0.0:8000`**

---

## Notes

* Ensure the **FTP server** is accessible and properly configured before running the service.
* Converted Markdown files are automatically placed under the `/md` directory on the FTP server.
