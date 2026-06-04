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

import os
import re
from typing import List

from pydantic import BaseModel, field_validator

class ConvertRequest(BaseModel):
    job_id: str
    file_name: str

    @field_validator("file_name")
    @classmethod
    def validate_file_name(cls, value: str) -> str:
        sanitized_name = os.path.basename(value)
        if not re.fullmatch(r"[A-Za-z0-9_-]+(\.[A-Za-z0-9]+)?", sanitized_name):
            raise ValueError(
                "Invalid file_name: only alphanumerics, hyphen, underscore, and an optional extension are allowed"
            )
        return sanitized_name

class BatchConvertRequest(BaseModel):
    requests: List[ConvertRequest]
