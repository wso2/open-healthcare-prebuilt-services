public type BulkExportKickoffResponse record {|
    string exportId;
    int httpStatus;
    string kickOffTime;
|};

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

public type BulkExportStatusConfig record {|
    string status;
    string location;
    string progress?;
    decimal interval;
    string exportId;
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
