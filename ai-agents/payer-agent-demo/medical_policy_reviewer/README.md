# Medical Policy Reviewer Agent

An AI-powered agent that automates the review and analysis of medical policies. This tool helps users efficiently process Payer's policy documents by extracting key information, identifying changes, and providing summaries.

## Features

- Automated analysis of medical policy documents
- Identification of policy changes between versions
- Extraction of key coverage details and clinical guidelines
- Generation of concise summaries for quick review
- Integration with existing document management systems

## Getting Started

### Prerequisites

- Ballerina
- BI VSCode Extension

### Configuration

Configure the `ANTHROPY_API_KEY` environment variable in the `Config.toml` file:

```toml
ANTHROPY_API_KEY="your_anthropy_api_key_here"
```

### Usage

```bash
bal run
```
