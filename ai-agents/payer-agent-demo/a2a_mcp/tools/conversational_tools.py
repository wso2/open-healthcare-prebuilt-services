import httpx
from mcp.shared._httpx_utils import create_mcp_http_client
from pydantic import Field
from utils.configs import ServerConfigs
from typing_extensions import Annotated
import logging


log = logging.getLogger(__name__)
configs = ServerConfigs()

def get_agent_url(agent: str) -> str:
    log.debug(f"Getting URL for agent: {agent}")
    if agent == "PolicyReviewer":
        return configs.POLICY_REVIEWER_URL
    elif agent == "MedicalReviewer":
        return configs.MEDICAL_REVIEWER_URL
    # elif agent == "PayerOrchestrator":
    #     return configs.PAYER_OCHESTRATOR_URL
    else:
        log.error(f"Unknown agent requested: {agent}")
        raise ValueError(f"Unknown agent: {agent}")
    

def register_tools(mcp):
    @mcp.tool(
        description=(
            "Used to send messages to Personal Policy Reviewer, and Medical Reviewer agents."
            "Use this tool when you need to send a message to one of these agents."
        )
    )
    async def send_message_to_policy_agents(
        agent: Annotated[
            str,
            Field(
                description="The agent to send the message to. Must be one of: PolicyReviewer, MedicalReviewer",
                examples=["PolicyReviewer", "MedicalReviewer"],
            ),
        ],
        conversationID: Annotated[
            str,
            Field(
                description="The unique identifier for the conversation. Autogenerate if not provided.",
                examples=["1", "2"],
            ),
        ],
        message: Annotated[str, Field(description="The message to send to the agent.")],
    ) -> dict:
        log.info(f"Sending message to {agent} agent for conversation: {conversationID}")
        agent_url = get_agent_url(agent)
        if log.isDebugEnabled():
            log.debug(f"Agent URL resolved to: {agent_url}")
        try:
            async with create_mcp_http_client() as client:
                response = await client.post(
                    agent_url, json={"sessionId": conversationID, "message": message}
                )
                response.raise_for_status()
                data = response.json()
                log.info(f"Successfully received response from {agent} agent")
                return data
        except httpx.HTTPStatusError as e:
            log.error(f"HTTP error from {agent} agent: {e.response.status_code}")
            return {"error": f"HTTP error occurred: {e.response.status_code} - {e.response.text}"}
        except Exception as e:
            log.error(f"Unexpected error sending message to {agent} agent: {str(e)}")
            return {"error": str(e)}
