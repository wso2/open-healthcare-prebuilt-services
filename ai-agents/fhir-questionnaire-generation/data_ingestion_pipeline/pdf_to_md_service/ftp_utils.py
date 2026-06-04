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

import io
import ftplib
import logging
import os
import tempfile
from settings import Configs

async def read_pdf_file_ftp(file_name: str, configs: Configs, logger: logging.Logger):
    """Read PDF file from FTP server and return local temporary file path."""
    ftp = None
    temp_file_path = None
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
            temp_file_path = temp_file.name
            ftp.retrbinary(f'RETR {pdf_filename}', temp_file.write)
        logger.info(f"Successfully downloaded PDF file for {file_name} from FTP server")
        return temp_file_path
    except Exception as e:
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        logger.error(f"Error reading PDF file from FTP: {e}")
        return None
    finally:
        # Ensure FTP connection is always closed
        if ftp is not None:
            try:
                ftp.quit()
            except Exception:
                ftp.close()
    
async def store_md_content_ftp(file_name: str, content: str, temp_file_path: str, configs: Configs, logger: logging.Logger):
    """Store markdown content in FTP server."""
    ftp = None
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
                return False
        # Prepare the markdown content as a file-like object
        md_filename = f"{file_name}.md"
        content_bytes = content.encode('utf-8')
        content_io = io.BytesIO(content_bytes)
        # Upload the file
        ftp.storbinary(f'STOR {md_filename}', content_io)
        logger.info(f"Successfully stored markdown content for {file_name} to FTP server")
        return True
    except Exception as e:
        logger.error(f"Error storing markdown content to FTP: {e}")
        return False
    finally:
        # Ensure FTP connection is always closed
        if ftp is not None:
            try:
                ftp.quit()
            except Exception:
                ftp.close()
        # Delete the temporary PDF file if it exists
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)

async def delete_pdf_file_ftp(file_name: str, configs: Configs, logger: logging.Logger):
    """Delete the original PDF file from the FTP server."""
    ftp = None
    try:
        ftp = ftplib.FTP()
        ftp.connect(configs.FTP_HOST, configs.FTP_PORT)
        ftp.login(configs.FTP_USERNAME, configs.FTP_PASSWORD)
        ftp.cwd('/pdf')
        ftp.delete(f"{file_name}.pdf")
        logger.info(f"Successfully deleted PDF file {file_name}.pdf from FTP server")
    except Exception as e:
        logger.error(f"Error deleting PDF file from FTP: {e}")
    finally:
        # Ensure FTP connection is always closed
        if ftp is not None:
            try:
                ftp.quit()
            except Exception:
                ftp.close()
