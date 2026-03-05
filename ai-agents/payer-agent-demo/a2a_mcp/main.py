from mcp.server.fastmcp import FastMCP
from tools.conversational_tools import register_tools
from typing import Dict
import logging
import sys
import signal

from tools.conversational_tools import configs

# Configure logging
logging.basicConfig(
    level=getattr(logging, configs.LOG_LEVEL.upper(), logging.INFO),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

fastmcp_kwargs: Dict = {
        "name": "A2A Conversation MCP",
        "instructions": "This server implements conversation tools for agents to communicate with each other.",
        "host": configs.HOST,
        "port": configs.PORT,
        "json_response": True,
        "stateless_http": True,
    }

def signal_handler(signum, frame):
    logger.info(f"Received signal {signum}. Shutting down gracefully...")
    sys.exit(0)

if __name__ == "__main__":
    # Set up signal handlers for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    try:
        logger.info(f"Starting MCP server on {configs.HOST}:{configs.PORT}")
        logger.info(f"Policy Reviewer URL: {configs.POLICY_REVIEWER_URL}")
        logger.info(f"Medical Reviewer URL: {configs.MEDICAL_REVIEWER_URL}")
        mcp = FastMCP(**fastmcp_kwargs)
        register_tools(mcp)
        logger.info("Registered conversational tools.")
        logger.info("Server starting...")
        mcp.run(transport='streamable-http')
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        sys.exit(1)
