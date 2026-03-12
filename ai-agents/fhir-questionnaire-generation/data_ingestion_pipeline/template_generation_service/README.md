# Scenario Extraction Service

The **Scenario Extraction Service** is responsible for transforming preprocessed policy document chunks into meaningful **scenarios** that serve as the foundation for **FHIR Questionnaire generation**.

The service first ingests supplementary information into a **vector database**, enabling contextually enriched processing. The **Scenario Extractor Agent** then leverages this information to analyze the core chunks and extract relevant, complete, and contextually accurate scenarios.

All extracted scenarios, along with their supplementary data, are stored in the vector database and the **FTP server** for further use in the **template generation pipeline**.

This is a **file-listener service**, continuously monitoring the `/chunks` directory on the FTP server where the **Policy Preprocessor Service** stores processed chunks.

---

## Prerequisites

* **Ballerina** must be installed on your system.
  👉 [Download Ballerina](https://ballerina.io/downloads/)

---

## Configuration

The service is configured using the `Config.toml` file located in the project root.
Key configuration parameters include:

| Configuration                   | Description                                                                                                                    |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **FTP Server Settings**         | Host, port, username, and password for FTP connectivity.                                                                       |
| **PGVector Database Settings**  | Connection details for the PGVector database, including host, port, user credentials, database name, and SSL certificate path. |
| **Anthropic / OpenAI API Keys** | API keys for the integrated language model used by the Scenario Extractor Agent.                                               |
| **Agent Settings**              | Controls for the number of tool calls and maximum chunks to retrieve per request.                                              |
| **Notification URL**            | Endpoint to send status updates after processing is complete.                                                                  |

Example configuration:

```toml
configurable string ANTHROPIC_API_KEY = ""
configurable string OPENAI_API_KEY = ""
configurable int MAX_TOOL_CALL = 3
configurable int MAX_CHUNKS = 3

configurable string PGVECTOR_HOST = ""
configurable int PGVECTOR_PORT = 12352
configurable string PGVECTOR_USER = ""
configurable string PGVECTOR_DATABASE = ""
configurable string PGVECTOR_PASSWORD = ""
configurable string CA_CERT_PATH = ""

configurable string NOTIFICATION_URL = "http://localhost:6080/notification"

configurable string FTP_HOST = ""
configurable int FTP_PORT = 2121
configurable string FTP_USERNAME = ""
configurable string FTP_PASSWORD = ""
```

---

## Setup Instructions

1. **Clone** the repository:

   ```bash
   git clone <repository_url>
   ```

2. **Navigate** to the project directory:

   ```bash
   cd scenario_extraction_service
   ```

3. **Run** the service:

   ```bash
   bal run
   ```

Ensure that both the **FTP server** and **PGVector database** are running and accessible with the provided configurations before starting the service.

---

## Notes

* The service automatically listens for new files under the `/chunks` directory on the FTP server.
* Extracted scenarios are stored in both the **PGVector database** and the **FTP server**, making them accessible to subsequent pipeline stages.
