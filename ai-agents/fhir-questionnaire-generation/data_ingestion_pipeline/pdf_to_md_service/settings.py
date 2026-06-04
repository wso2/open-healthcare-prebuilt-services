# Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
#
# WSO2 LLC. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

from pydantic_settings import BaseSettings, SettingsConfigDict

class Configs(BaseSettings):
    "Contains Environment vaiables for Document Service"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # FTP or Local File Storage Configs
    USE_FTP: bool = False  # Set to True to use FTP server, False to use local storage

    # FTP Configs
    FTP_HOST: str = "127.0.0.1"
    FTP_PORT: int = 2121
    FTP_USERNAME: str = "ftp_user"
    FTP_PASSWORD: str = "ftp_password"

    # Local Storage Configs
    LOCAL_DIR: str = "../../data/"

    # Notification Callback URL
    NOTIFICATION_CALLBACK_URL: str = "http://localhost:6080/notification"
