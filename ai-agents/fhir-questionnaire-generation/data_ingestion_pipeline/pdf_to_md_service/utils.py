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

import logging
from docling.document_converter import DocumentConverter

def convert_pdf_to_markdown(pdfFile) -> str:
    """
    Convert a PDF document to Markdown format and save it to the specified directory.

    Args:
        source (str): The path or URL of the PDF document to convert.
        output_dir (str): The directory where the Markdown file will be saved.
    """
    logger = logging.getLogger(__name__)
    try:
        logger.info(f"Starting PDF to Markdown conversion for file: {pdfFile}")
        converter = DocumentConverter()
        result = converter.convert(pdfFile)
        markdown_content = result.document.export_to_markdown()
        logger.info("PDF to Markdown conversion completed successfully")
        return markdown_content
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        raise e

def save_file(file_path: str, content: str) -> None:
    with open(file_path, "w") as f:
        f.write(content)
