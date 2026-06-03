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

import httpx
import logging
import pymupdf4llm
from settings import Configs

from ftp_utils import read_pdf_file_ftp, store_md_content_ftp, delete_pdf_file_ftp
from file_utils import read_pdf_file_local, store_md_content_local, delete_pdf_file_local

def convert_pdf_to_markdown(pdfFile, logger: logging.Logger) -> str:
    """
    Convert a PDF document to Markdown format and save it to the specified directory.

    Args:
        source (str): The path or URL of the PDF document to convert.
        output_dir (str): The directory where the Markdown file will be saved.
    """
    try:
        logger.info(f"Starting PDF to Markdown conversion for file: {pdfFile}")
        markdown_content = pymupdf4llm.to_markdown(pdfFile)
        logger.info("PDF to Markdown conversion completed successfully")
        return markdown_content
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        raise e

def save_file(file_path: str, content: str) -> None:
    with open(file_path, "w") as f:
        f.write(content)

async def send_notification(job_id: str, file_name: str, status: str, message: str, configs: Configs, logger: logging.Logger):
    """Send notification to the callback URL."""
    try:
        payload = {
            "job_id": job_id,
            "file_name": file_name,
            "status": status,
            "message": message
        }
        logger.info(f"Sending notification to {configs.NOTIFICATION_CALLBACK_URL}: {payload}")
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(configs.NOTIFICATION_CALLBACK_URL, json=payload)
            if response.status_code == 200:
                logger.info(f"Notification sent successfully for job {job_id}")
            else:
                logger.warning(f"Notification failed with status {response.status_code} for job {job_id}")
    except Exception as e:
        logger.error(f"Failed to send notification for job {job_id}: {e}")

async def process_pdf_file(job_id: str, file_name: str, logger: logging.Logger, configs: Configs):
    """Background task to process PDF file conversion."""
    file_path = None
    try:
        logger.info(f"Job {job_id} started processing for file {file_name}")
        file_path = None
        if configs.USE_FTP:
            file_path = await read_pdf_file_ftp(file_name, configs, logger)
        else:
            file_path = await read_pdf_file_local(file_name, configs, logger)
        if not file_path:
            logger.error(f"Job {job_id} failed - PDF file not found")
            await send_notification(job_id, file_name, "failed", "pdf_not_found", configs, logger)
            return
        
        # Convert PDF to markdown
        markdown_content = convert_pdf_to_markdown(file_path, logger)
        if markdown_content:
            # Store the markdown content
            if configs.USE_FTP:
                storage_success = await store_md_content_ftp(file_name, markdown_content, file_path, configs, logger)
            else:
                storage_success = await store_md_content_local(file_name, markdown_content, configs, logger)
            logger.info(f"Storage success: {storage_success}")
            if storage_success:
                logger.info(f"Job {job_id} completed successfully")
                await send_notification(job_id, file_name, "completed", "pdf_to_md_done", configs, logger)
                if configs.USE_FTP:
                    await delete_pdf_file_ftp(file_name, configs, logger)
                else:
                    await delete_pdf_file_local(file_name, configs, logger)
            else:
                logger.error(f"Job {job_id} failed during storage")
                await send_notification(job_id, file_name, "failed", "storage_failed", configs, logger)
        else:
            logger.error(f"Job {job_id} failed during conversion")
            await send_notification(job_id, file_name, "failed", "conversion_failed", configs, logger)
    except Exception as e:
        logger.error(f"Error processing job {job_id}: {e}")
        await send_notification(job_id, file_name, "failed", f"error: {str(e)}", configs, logger)
