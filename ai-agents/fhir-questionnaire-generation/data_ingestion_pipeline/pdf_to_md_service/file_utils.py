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
import asyncio
import logging
import tempfile
from settings import Configs

async def read_pdf_file_local(file_name: str, configs: Configs, logger: logging.Logger):
    """Read a PDF file from local storage and copy it to a temporary file.

    Note:
        The returned temporary file path is owned by the caller. The caller is
        responsible for deleting the file after processing.
    """
    try:
        # Prepare the PDF filename
        pdf_filename = os.path.join(configs.LOCAL_DIR, "pdf", f"{file_name}.pdf")

        def _copy_pdf_to_temp() -> str:
            temp_file_path = None
            try:
                # Create a temporary file to store the PDF
                with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
                    temp_file_path = temp_file.name
                    # Read the PDF file from local storage and copy content
                    with open(pdf_filename, 'rb') as f:
                        temp_file.write(f.read())
                return temp_file_path
            except Exception:
                if temp_file_path and os.path.exists(temp_file_path):
                    os.remove(temp_file_path)
                raise

        loop = asyncio.get_running_loop()
        temp_file_path = await loop.run_in_executor(None, _copy_pdf_to_temp)
        logger.info(f"Successfully read PDF file for {file_name} from local storage")
        return temp_file_path
    except Exception as e:
        logger.error(f"Error reading PDF file from local storage: {e}")
        return None
    
async def store_md_content_local(file_name: str, content: str, configs: Configs, logger: logging.Logger):
    """Store markdown content in local storage."""
    try:
        # Prepare the markdown filename
        md_dir = os.path.join(configs.LOCAL_DIR, "md")
        os.makedirs(md_dir, exist_ok=True)
        md_filename = os.path.join(md_dir, f"{file_name}.md")
        # Write the markdown content to a local file
        with open(md_filename, 'w', encoding='utf-8') as f:
            f.write(content)
        logger.info(f"Successfully stored markdown content for {file_name} to local storage")
        return True
    except Exception as e:
        logger.error(f"Error storing markdown content to local storage: {e}")
        return False

async def delete_pdf_file_local(file_name: str, configs: Configs, logger: logging.Logger):
    """Delete the original PDF file from local storage."""
    try:
        pdf_filename = os.path.join(configs.LOCAL_DIR, "pdf", f"{file_name}.pdf")
        os.remove(pdf_filename)
        logger.info(f"Successfully deleted PDF file {file_name}.pdf from local storage")
    except Exception as e:
        logger.error(f"Error deleting PDF file from local storage: {e}")
