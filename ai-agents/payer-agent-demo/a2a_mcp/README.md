# A2A MCP Server

A Model Context Protocol (MCP) server that enables agent-to-agent communication for healthcare and insurance workflows. This server provides tools for orchestrating conversations between specialized agents like Policy Reviewers and Medical Reviewers.

## Features

- **Agent Communication**: Send messages between specialized agents through a unified interface
- **Session Management**: Handle conversation sessions with unique identifiers
- **HTTP Transport**: Built on FastMCP with streamable HTTP transport
- **Healthcare Focus**: Designed specifically for policy and medical review workflows

## Supported Agents

- **PolicyReviewer**: Handles insurance policy-related queries and reviews
- **MedicalReviewer**: Processes medical documentation and assessments

## Installation

### Prerequisites

- Python 3.9 or higher
- Environment variables configured (see Configuration section)

### Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file with the required configuration (see Configuration section)

4. Run the server:
   ```bash
   python main.py
   ```

## Configuration

Create a `.env` file in the project root with the following variables:

```env
POLICY_REVIEWER_URL=http://your-policy-reviewer-endpoint
MEDICAL_REVIEWER_URL=http://your-medical-reviewer-endpoint
```

## Usage

The server runs on `localhost:3001` and provides the following MCP tool:

### `send_message_to_policy_agents`

Send messages to policy or medical review agents.

**Parameters:**
- `agent` (string): Target agent (`PolicyReviewer` or `MedicalReviewer`)
- `conversationID` (string): Unique session identifier
- `message` (string): Message content to send

**Example:**
```json
{
  "agent": "PolicyReviewer",
  "conversationID": "session-123",
  "message": "Please review this policy claim for coverage eligibility."
}
```
