// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

# Source Server config, this server should support $export operation.
#
# + baseUrl - Base URL of the server  
# + tokenUrl - token endpoint URL 
# + clientId - client ID  
# + clientSecret - client secret
# + scopes - array of scopes, to access the export operation  
# + fileServerUrl - if the server exports to different file server, this URL should be provided  
# + contextPath - context path for the export operation, if any  
# + defaultIntervalInSec - polling interval in seconds
public type BulkExportServerConfig record {|
    string baseUrl;
    string tokenUrl;
    string clientId;
    string clientSecret;
    string[] scopes;
    string fileServerUrl;
    string contextPath;
    decimal defaultIntervalInSec;
|};

# Server config for import FHIR resources.
#
# + 'type - FHIR or FTP  
# + host - host name of the server
# + port - port number of the server
# + username - user name to access the server, for ftp
# + password - password to access the server, for ftp
# + directory - directory to save the exported files
public type TargetServerConfig record {|
    string 'type;
    string host;
    int port;
    string username;
    string password;
    string directory;
|};

# Configs for pre built service.
#
# + port - port number of the service 
# + authEnabled - true if the bulk export server requires authentication
# + targetDirectory - temporary directory to save the exported files
public type BulkExportClientConfig record {|
    int port;
    boolean authEnabled;
    string targetDirectory;
|};

# record to map exported resource metadata.
#
# + 'type - file type
# + url - downloadable location of the file
# + count - record count
public type OutputFile record {|
    string 'type;
    string url;
    int count;
|};

# record to hold summary of exports.
#
# + transactionTime - time of the transaction 
# + request - request description
# + requiresAccessToken - authentication required or not
# + output - output files 
# + deleted - deleted files
# + 'error - error files
public type ExportSummary record {
    string transactionTime;
    string request;
    boolean requiresAccessToken;
    OutputFile[] output;
    string[] deleted;
    string[] 'error;
};

# Record to hold matched patients.
#
# + id - patient ID
# + canonical - canonical URL
# + identifiers - other identifiers
public type MatchedPatient record {|
    string id;
    string canonical?;
    map<string> identifiers?;
|};
