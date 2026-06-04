// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

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
import ballerina/file;
import ballerina/ftp;

function initializeStorageDirectories() returns error? {
    if STORAGE_TYPE == "local" {
        string[] requiredDirs = [
            LOCAL_STORAGE_PATH + "/pdf",
            LOCAL_STORAGE_PATH + "/md",
            LOCAL_STORAGE_PATH + "/chunks"
        ];
        foreach string dir in requiredDirs {
            if !check file:test(dir, file:EXISTS) {
                check file:createDir(dir, file:RECURSIVE);
                log:printInfo("Created storage directory: " + dir);
            }
        }
        log:printInfo("Storage directories initialized at: " + LOCAL_STORAGE_PATH);
    }
}

function storageGet(string path) returns stream<byte[] & readonly, io:Error?>|error {
    if STORAGE_TYPE == "local" {
        string fullPath = LOCAL_STORAGE_PATH + path;
        log:printDebug("Reading from local storage: " + fullPath);
        return check io:fileReadBlocksAsStream(fullPath);
    } else {
        log:printDebug("Reading from FTP storage: " + path);
        ftp:Client? ftpClient = fileClient;
        if ftpClient is ftp:Client {
            var result = ftpClient->get(path);
            if result is error {
                log:printError("Error fetching file from FTP: " + result.message());
                return result;
            }
            return result;
        }
        return error("FTP client not initialized");
    }
}

function storagePut(string path, stream<byte[] & readonly, io:Error?>|json content) returns error? {
    if STORAGE_TYPE == "local" {
        string fullPath = LOCAL_STORAGE_PATH + path;
        log:printDebug("Writing to local storage: " + fullPath);
        
        string dirPath = check file:parentPath(fullPath);
        if !check file:test(dirPath, file:EXISTS) {
            check file:createDir(dirPath, file:RECURSIVE);
        }
        
        if content is json {
            check io:fileWriteJson(fullPath, content);
        } else {
            check io:fileWriteBlocksFromStream(fullPath, content);
        }
    } else {
        log:printDebug("Writing to FTP storage: " + path);
        ftp:Client? ftpClient = fileClient;
        if ftpClient is ftp:Client {
            check ftpClient->put(path, content);
        } else {
            return error("FTP client not initialized");
        }
    }
}

function storageDelete(string path) returns error? {
    if STORAGE_TYPE == "local" {
        string fullPath = LOCAL_STORAGE_PATH + path;
        log:printDebug("Deleting from local storage: " + fullPath);
        check file:remove(fullPath);
    } else {
        ftp:Client? ftpClient = fileClient;
        if ftpClient is ftp:Client {
            check ftpClient->delete(path);
        } else {
            return error("FTP client not initialized");
        }
    }
}

function storageExists(string path) returns boolean|error {
    if STORAGE_TYPE == "local" {
        string fullPath = LOCAL_STORAGE_PATH + path;
        return check file:test(fullPath, file:EXISTS);
    } else {
        ftp:Client? ftpClient = fileClient;
        if ftpClient is ftp:Client {
            var result = ftpClient->get(path);
            if result is error {
                return false;
            }
            return true;
        }
        return error("FTP client not initialized");
    }
}
