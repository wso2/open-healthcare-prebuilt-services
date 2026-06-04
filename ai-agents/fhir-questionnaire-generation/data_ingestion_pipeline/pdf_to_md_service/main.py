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
import logging
import uvicorn
from typing import Dict
from settings import Configs
from models import ConvertRequest, BatchConvertRequest
from fastapi import FastAPI, HTTPException, BackgroundTasks

from utils import process_pdf_file


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

configs = Configs()

app = FastAPI(
    title="PDF to Markdown Converter Service",
    description="A service that converts PDF files to Markdown format and stores them in a database",
    version="1.0.0"
)

@app.post("/convert", response_model=Dict[str, str])
async def convert_pdf_to_md(
    request: ConvertRequest,
    background_tasks: BackgroundTasks
) -> Dict[str, str]:
    """
    Give the job ID and filename, process the PDF to Markdown conversion in the background.
    """
    try:
        # Validate input parameters
        if not request.job_id or not request.job_id.strip():
            raise HTTPException(status_code=400, detail="job_id is required")
        
        if not request.file_name or not request.file_name.strip():
            raise HTTPException(status_code=400, detail="file_name is required")
        
        logger.info(f"Received conversion request - job_id: {request.job_id}, file_name: {request.file_name}")
        # Start background processing
        background_tasks.add_task(
            process_pdf_file, 
            request.job_id.strip(),
            request.file_name.strip(),
            logger,
            configs
        )
        return {
            "job_id": request.job_id,
            "filename": request.file_name,
            "status": "started",
            "message": "File uploaded successfully. Processing started."
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Processing failed: {str(e)}")

@app.post("/convert/batch", response_model=Dict[str, str])
async def batch_convert_pdf_to_md(
    request: BatchConvertRequest,
    background_tasks: BackgroundTasks
) -> Dict[str, str]:
    """
    Batch convert multiple PDF files to Markdown format.
    Accepts a list of conversion requests and processes them all in background.
    """
    if not request.requests:
        raise HTTPException(status_code=400, detail="No conversion requests provided")

    for req in request.requests:
        if not req.job_id or not req.job_id.strip():
            raise HTTPException(status_code=400, detail="job_id is required for all requests")
        if not req.file_name or not req.file_name.strip():
            raise HTTPException(status_code=400, detail="file_name is required for all requests")

        logger.info(f"Queuing batch conversion - job_id: {req.job_id}, file_name: {req.file_name}")
        background_tasks.add_task(
            process_pdf_file,
            req.job_id.strip(),
            req.file_name.strip(),
            logger,
            configs
        )

    return {
        "status": "started",
        "message": f"Batch processing started for {len(request.requests)} file(s)"
    }

@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "PDF to Markdown Converter"
    }

if __name__ == "__main__":
    port = int(os.environ.get("SERVICE_PORT", "8000"))
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=port, 
        reload=os.environ.get("RELOAD", "false").lower() == "true",
        log_level="info"
    )
