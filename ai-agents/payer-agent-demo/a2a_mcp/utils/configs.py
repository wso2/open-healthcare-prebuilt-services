import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class ServerConfigs(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    POLICY_REVIEWER_URL: str = ""
    MEDICAL_REVIEWER_URL: str = ""
    HOST: str = "0.0.0.0"
    PORT: int = 3001 
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    # PAYER_OCHESTRATOR_URL: str
