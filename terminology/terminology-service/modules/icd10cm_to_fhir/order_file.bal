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

// Fixed-width column layout of icd10cm-order-<year>.txt, 0-indexed and
// verified against the real FY2027 release:
//   cols 0-4   (5 chars): order number - unused
//   col  5             : space
//   cols 6-12  (7 chars): raw code, no decimal point, space-padded
//   col  13            : space
//   col  14            : billable flag, "0" or "1"
//   col  15            : space
//   cols 16-75 (60 chars): short description - unused, redundant with long description
//   col  76+           : long description (canonical display text)
const int ORDER_FILE_RAW_CODE_START = 6;
const int ORDER_FILE_RAW_CODE_END = 13;
const int ORDER_FILE_BILLABLE_FLAG_INDEX = 14;
const int ORDER_FILE_LONG_DESC_START = 76;

// The shortest a well-formed line can be: enough columns to read the
// billable flag and at least reach where the long description starts.
const int ORDER_FILE_MIN_LINE_LENGTH = 77;

# A single parsed row of the ICD-10-CM order file.
#
# + rawCode - The code exactly as it appears in the file, with no decimal point (e.g. "E111")
# + code - The canonical dotted FHIR code (e.g. "E11.1"), or the raw code unchanged for 3-character category codes
# + billable - `true` if this code can be used for billing (a leaf code); `false` for non-billable header/category codes
# + display - The long description, used as the concept's display text
public type OrderFileRow record {|
    string rawCode;
    string code;
    boolean billable;
    string display;
|};

# Inserts a decimal point after the third character of a raw ICD-10-CM code,
# the rule that turns the order file's undotted codes (e.g. "E111", "A0100")
# into their canonical dotted form (e.g. "E11.1", "A01.00"). Codes of three
# characters or fewer (category codes, e.g. "E11") are returned unchanged.
#
# + rawCode - The raw, undotted code
# + return - The canonical dotted code
public isolated function formatIcd10cmCode(string rawCode) returns string {
    string trimmed = rawCode.trim();
    if trimmed.length() > 3 {
        return trimmed.substring(0, 3) + "." + trimmed.substring(3);
    }
    return trimmed;
}

# Streams the ICD-10-CM order file and parses every row. Malformed lines
# (shorter than the fixed-width layout requires) are skipped rather than
# failing the whole import.
#
# + filePath - The path to `icd10cm-order-<year>.txt`
# + return - A tuple of the parsed rows, in file order, and the number of rows read, or an `error` if the file can't be read
public isolated function streamOrderFile(string filePath) returns [OrderFileRow[], int]|error {
    OrderFileRow[] rows = [];
    int rowsRead = 0;

    stream<string, io:Error?> lineStream = check io:fileReadLinesAsStream(filePath);
    record {|string value;|}|io:Error? next = lineStream.next();
    while next is record {|string value;|} {
        string line = next.value;
        if line.length() >= ORDER_FILE_MIN_LINE_LENGTH {
            string rawCode = line.substring(ORDER_FILE_RAW_CODE_START, ORDER_FILE_RAW_CODE_END).trim();
            string billableFlag = line.substring(ORDER_FILE_BILLABLE_FLAG_INDEX, ORDER_FILE_BILLABLE_FLAG_INDEX + 1);
            string display = line.substring(ORDER_FILE_LONG_DESC_START).trim();
            if rawCode != "" {
                rowsRead += 1;
                rows.push({
                    rawCode: rawCode,
                    code: formatIcd10cmCode(rawCode),
                    billable: billableFlag == "1",
                    display: display
                });
            }
        }
        next = lineStream.next();
    }
    io:Error? closeResult = lineStream.close();
    if next is io:Error {
        return next;
    }
    if closeResult is io:Error {
        return closeResult;
    }
    return [rows, rowsRead];
}
