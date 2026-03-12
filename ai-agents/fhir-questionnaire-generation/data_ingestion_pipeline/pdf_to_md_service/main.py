# Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).

# WSO2 LLC. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

import io
import os
import httpx
import ftplib
import logging
import uvicorn
import tempfile
from typing import Dict, Any
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel

from settings import Configs
from utils import convert_pdf_to_markdown

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

configs = Configs()
# HTTP client for UI notifications with retry configuration
notification_client = None
class ConvertRequest(BaseModel):
    job_id: str
    file_name: str

async def send_notification(payload: Dict[str, Any]):
    try:
        headers = {
            "Content-Type": "application/json"
        }
        response = await notification_client.post(
            configs.NOTIFICATION_URL, 
            json=payload, 
            headers=headers
        )
        if response.status_code in [200, 202]:
            logger.info(f"Successfully sent UI notification: {payload}")
            return True
        else:
            logger.error(f"UI notification failed. Status: {response.status_code}, Response: {response.text}")
    except Exception as e:
        logger.error(f"Error sending UI notification")
    return False

async def read_pdf_file(file_name: str):
    """Read PDF file from FTP server and return local temporary file path."""
    try:
        # Connect to FTP server
        ftp = ftplib.FTP()
        ftp.connect(configs.FTP_HOST, configs.FTP_PORT)
        ftp.login(configs.FTP_USERNAME, configs.FTP_PASSWORD)
        # Change to the pdf directory
        ftp.cwd('/pdf')
        # Prepare the PDF filename
        pdf_filename = f"{file_name}.pdf"
        # Create a temporary file to store the downloaded PDF
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
            # Download the PDF file from FTP server
            ftp.retrbinary(f'RETR {pdf_filename}', temp_file.write)
            temp_file_path = temp_file.name
        # Close the FTP connection
        ftp.quit()
        logger.info(f"Successfully downloaded PDF file for {file_name} from FTP server")
        return temp_file_path
    except Exception as e:
        logger.error(f"Error reading PDF file from FTP: {e}")
        return None

async def store_md_content(file_name: str, content: str):
    """Store markdown content in FTP server."""
    try:
        # Connect to FTP server
        ftp = ftplib.FTP()
        ftp.connect(configs.FTP_HOST, configs.FTP_PORT)
        ftp.login(configs.FTP_USERNAME, configs.FTP_PASSWORD)
        # Change to the md directory (create if it doesn't exist)
        try:
            ftp.cwd('/md')
        except ftplib.error_perm:
            # Directory doesn't exist, try to create it
            try:
                ftp.mkd('/md')
                ftp.cwd('/md')
            except ftplib.error_perm as e:
                logger.error(f"Failed to create or access /md directory: {e}")
                ftp.quit()
                return False
        # Prepare the markdown content as a file-like object
        md_filename = f"{file_name}.md"
        content_bytes = content.encode('utf-8')
        content_io = io.BytesIO(content_bytes)
        # Upload the file
        ftp.storbinary(f'STOR {md_filename}', content_io)
        # Close the FTP connection
        ftp.quit()
        logger.info(f"Successfully stored markdown content for {file_name} to FTP server")
        return True
    except Exception as e:
        logger.error(f"Error storing markdown content to FTP: {e}")
        return False

@asynccontextmanager
async def lifespan(app: FastAPI):
    global notification_client
    notification_client = httpx.AsyncClient()
    logger.info("Store service integration initialized")
    yield
    if notification_client:
        await notification_client.aclose()

app = FastAPI(
    title="PDF to Markdown Converter Service",
    description="A service that converts PDF files to Markdown format and stores them in a database",
    version="1.0.0",
    lifespan=lifespan
)

async def process_pdf_file(job_id: str, file_name: str):
    """Background task to process PDF file conversion."""
    file_path = None
    try:
        # Send started notification to UI
        message = {
            "status": "started",
            "job_id": job_id,
            "file_name": file_name,
            "message": "pdf_to_md"
        }
        await send_notification(message)

        # Read the PDF file from FTP server
        file_path = await read_pdf_file(file_name)
        
        if not file_path:
            message = {
                "status": "failed",
                "job_id": job_id,
                "file_name": file_name,
                "message": "pdf_to_md_file_not_found"
            }
            await send_notification(message)
            logger.error(f"Job {job_id} failed - PDF file not found")
            return
        
        # Convert PDF to markdown
        markdown_content = convert_pdf_to_markdown(file_path)
        
        if markdown_content:
            # Store the markdown content
            storage_success = await store_md_content(file_name, markdown_content)

            logger.info(f"Storage success: {storage_success}")
            
            if storage_success:
                # Send completion notification to UI
                message = {
                    "status": "completed",
                    "job_id": job_id,
                    "file_name": file_name,
                    "message": "pdf_to_md_done"
                }
                await send_notification(message)
                logger.info(f"Job {job_id} completed successfully")
            else:
                message = {
                    "status": "failed",
                    "job_id": job_id,
                    "file_name": file_name,
                    "message": "pdf_to_md_storage_failed"
                }
                await send_notification(message)
                logger.error(f"Job {job_id} failed during storage")
        else:
            message = {
                "status": "failed",
                "job_id": job_id,
                "file_name": file_name,
                "message": "pdf_to_md_failed"
            }
            await send_notification(message)
            logger.error(f"Job {job_id} failed during conversion")
            
    except Exception as e:
        logger.error(f"Error processing job {job_id}: {e}")
        # Send error notification
        message = {
            "status": "error",
            "job_id": job_id,
            "file_name": file_name,
            "message": f"pdf_to_md_error: {str(e)}"
        }
        await send_notification(message)
    finally:
        # Clean up temporary file
        if file_path and os.path.exists(file_path):
            os.unlink(file_path)
            logger.info(f"Cleaned up temporary file: {file_path}")

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
            request.file_name.strip()
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

@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "PDF to Markdown Converter"
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True,
        log_level="info"
    )
