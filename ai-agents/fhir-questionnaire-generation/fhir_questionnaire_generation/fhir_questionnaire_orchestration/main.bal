// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/log;
import ballerina/ftp;
import ballerina/regex;

listener ftp:Listener fileListener = new ({
    host: FTP_HOST,
    port: FTP_PORT,
    auth: {
        credentials: {
            username: FTP_USERNAME,
            password: FTP_PASSWORD
        }
    },
    path: "/prompts",
    fileNamePattern: "(.*).json"
});

service on fileListener {
    remote function onFileChange(ftp:WatchEvent & readonly event, ftp:Caller caller) returns error? {
        log:printInfo("File change event received: " + event.toString());
        foreach ftp:FileInfo addedFile in event.addedFiles {
            stream<byte[] & readonly, io:Error?> fileStream = check caller->get(addedFile.pathDecoded);
            // Get the file name without the extension
            string fileName = addedFile.name;
            string fileNameWithoutExt = regex:split(fileName, "\\.")[0];
            log:printInfo("Processing file: " + fileNameWithoutExt);
            // Read the file content from the stream
            string fileContent = "";
            byte[][] & readonly chunks = check from byte[] & readonly chunk in fileStream
                select chunk;
            foreach byte[] & readonly chunk in chunks {
                fileContent += check string:fromBytes(chunk);
            }
            json obj = check fileContent.fromJsonString();
            PromptStore chunkStore = check obj.fromJsonWithType(PromptStore);
            check fileStream.close();
            // Delete the file from the SFTP server after reading.
            check caller->delete(addedFile.pathDecoded);
            check orchestrateConversation(chunkStore.templates, fileNameWithoutExt);
            log:printInfo("Finished processing file: " + fileNameWithoutExt);
        }
    }
}
