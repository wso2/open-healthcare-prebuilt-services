# Policy Document Chunker

The **Policy Document Chunker** is the core preprocessing module for **Payers’ Policy Documents**. It ingests raw policy documents, processes them into structured and manageable chunks, and prepares them for downstream **scenario extraction** tasks.

This service facilitates seamless data transfer through an **FTP server** and ensures reliable integration with other modules in the ecosystem.

---

## Exposed Endpoints

| Method   | Endpoint          | Description                                                                                                                                                                                 |
| -------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GET**  | `/health`         | Health check endpoint to verify the service is running.                                                                                                                                     |
| **POST** | `/uploadPolicy`   | Upload raw policy documents for preprocessing.                                                                                                                                              |
| **POST** | `/questionnaires` | Create processed questionnaires from preprocessed data.                                                                                                                                     |
| **GET**  | `/questionnaires` | Retrieve processed questionnaires.                                                                                                                                                          |
| **POST** | `/notification`   | Send notifications upon completion of processing tasks. This is a centralized notification endpoint used to update the UI or other services on the status of FHIR Questionnaire generation. |

---

## Prerequisites

* **Ballerina** must be installed on your system.
  👉 [Download Ballerina](https://ballerina.io/downloads/)

---

## Configuration

The service can be configured via the `Config.toml` file located in the project root. Key configuration parameters include:
* **FTP Server Settings**: Host, port, username, and password for connecting to the FTP server.
* **Anthropic API Key**: For integrating with the Anthropic language model.
```sh
FTP_HOST=""
FTP_PORT=21
FTP_USERNAME=""
FTP_PASSWORD=""

ANTHROPIC_API_KEY=""
```

## Setup Instructions

1. **Clone** the repository:

   ```bash
   git clone <repository_url>
   ```
2. **Navigate** to the project directory:

   ```bash
   cd policy_preprocessor
   ```
3. **Run** the service:

   ```bash
   bal run
   ```
4. The service will be available at:
   **`http://localhost:6080`**
