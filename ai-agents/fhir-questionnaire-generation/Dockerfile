# ═══════════════════════════════════════════════════════════════
#  FHIR Questionnaire Generation Pipeline — Single Container
#  Only the Policy Preprocessor (port 6080) is exposed.
# ═══════════════════════════════════════════════════════════════

# ── Stage 1: Build all four Ballerina services ─────────────────
FROM ballerina/ballerina:2201.12.10 AS bal-build
USER root

# Policy Preprocessor
WORKDIR /build/policy-preprocessor
COPY data_ingestion_pipeline/policy_preprocessor/ .
RUN rm -f Dependencies.toml && bal build

# Questionnaire Orchestration
WORKDIR /build/orchestration
COPY fhir_questionnaire_generation/fhir_questionnaire_orchestration/ .
RUN rm -f Dependencies.toml && bal build


# ── Stage 2: Runtime ──────────────────────────────────────────
FROM python:3.12-slim

# Install Java 21 (Eclipse Temurin) + Node.js 20 LTS + curl for health checks
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget gnupg ca-certificates curl \
        libgl1 libglib2.0-0 && \
    # Add Eclipse Temurin APT repository
    mkdir -p /etc/apt/keyrings && \
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] \
        https://packages.adoptium.net/artifactory/deb \
        $(. /etc/os-release && echo $VERSION_CODENAME) main" \
        > /etc/apt/sources.list.d/adoptium.list && \
    # Add NodeSource repository for Node.js 20
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends temurin-21-jre nodejs && \
    # Clean up
    apt-get purge -y wget gnupg && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ── Python dependencies (cached layer) ────────────────────────
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
COPY data_ingestion_pipeline/pdf_to_md_service/requirements.txt /tmp/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system -r /tmp/requirements.txt && rm /tmp/requirements.txt

# ── Copy Python service ───────────────────────────────────────
COPY data_ingestion_pipeline/pdf_to_md_service/ /app/services/pdf-to-md/

# ── Copy Ballerina JARs ───────────────────────────────────────
COPY --from=bal-build /build/policy-preprocessor/target/bin/policy_document_chunker.jar \
     /app/services/policy-preprocessor/app.jar

COPY --from=bal-build /build/orchestration/target/bin/fhir_questionnaire_generation.jar \
     /app/services/orchestration/app.jar

# ── Copy CQL Enrichment API (Node.js) ─────────────────────────
COPY fhir_questionnaire_generation/cql-enrichment-api/ /app/services/cql-enrichment-api/
RUN cd /app/services/cql-enrichment-api && npm install

# ── Create non-root user ──────────────────────────────────────
RUN addgroup --gid 10014 appgroup && \
    adduser --uid 10014 --gid 10014 --disabled-password --gecos "" appuser && \
    chown -R 10014:10014 /app

# ── Entrypoint ────────────────────────────────────────────────
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# ── Debug: verify what was copied ─────────────────────────────
RUN echo "========== /app contents ==========" && \
    find /app -type f | sort && \
    echo "========== entrypoint.sh ==========" && \
    ls -la /app/entrypoint.sh && \
    echo "========== services ==========" && \
    ls -laR /app/services/ && \
    echo "=================================="

# ── Default environment (all services talk via localhost) ──────
ENV STORAGE_TYPE=local \
    LOCAL_STORAGE_PATH=/app/data \
    LOCAL_DIR=/app/data \
    USE_FTP=false \
    NOTIFICATION_CALLBACK_URL=http://localhost:6080/notification \
    PDF_TO_MD_SERVICE_URL=http://localhost:8000 \
    FHIR_QUESTIONNAIRE_SERVICE_URL=http://localhost:6060/generate \
    FHIR_SERVER_URL=http://localhost:9090/fhir/r4 \
    POLICY_FLOW_ORCHESTRATOR=http://localhost:6080 \
    CQL_ENRICHMENT_API_URL=http://localhost:3000 \
    FHIR_QUESTIONNAIRE_GENERATOR_URL= \
    FHIR_REVIEWER_URL=

# Only expose the Policy Preprocessor to the outside world
EXPOSE 6080

USER 10014

ENTRYPOINT ["/app/entrypoint.sh"]
