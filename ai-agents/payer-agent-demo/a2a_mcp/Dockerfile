
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv (for fast dependency management)
RUN pip install --upgrade pip

# Set workdir
WORKDIR /app

# Copy only requirements first for better caching
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Copy the rest of the code
COPY . .

# Make startup script executable
RUN chmod +x startup.sh

# Create a non-root user with UID 10001 and switch to it
RUN useradd -m -u 10001 appuser && \
    chown -R appuser:appuser /app
USER 10001

# Expose MCP server port (use 3001 for Choreo compatibility)
EXPOSE 3001

# Command to run the application
CMD ["./startup.sh"]
