
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

// have a generic config for source server and target server for FHIR cases
// check Ballerina FTP client for the FTP server config

public type BulkExportClientConfig record {|
    int port;
    boolean authEnabled;
    string targetDirectory;
|};

public type FtpServerConfig record {|
    boolean enabled;
    string host;
    int port;
    string username;
    string password;
    string directory;
|};

public type OutputFile record {|
    string 'type;
    string url;
    int count;
|};

public type ExportSummary record {|
    string transactionTime;
    string request;
    boolean requiresAccessToken;
    OutputFile[] output;
    string[] deleted;
    string[] 'error;
|};

public type MatchedPatient record {|
    string id;
    string canonical?;
    map<string> identifiers?;
|};
