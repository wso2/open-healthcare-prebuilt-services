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

import ballerina/file;

const string ORDER_FILE_MUST_CONTAIN = "order";
const string ORDER_FILE_MUST_NOT_CONTAIN = "addenda";
const string ORDER_FILE_EXTENSION = ".txt";

const string TABULAR_XML_MUST_CONTAIN = "tabular";
const string TABULAR_XML_EXTENSION = ".xml";

// Category codes are always exactly 3 characters (e.g. "E11"); anything
// longer is a subcategory/leaf code whose parent is derived by truncation.
const int CATEGORY_CODE_LENGTH = 3;

# Parses the ICD-10-CM tabular XML and order file under a release directory
# and merges them into a single, topologically-sorted concept list ready for
# insertion. Chapters and sections come from the tabular XML; every other
# concept comes from the order file, with its parent resolved via the
# truncate-last-character rule (category codes instead resolve their parent
# through the tabular XML's category -> section mapping, since a 3-character
# code's section parent can't be derived from the code string).
#
# + dirPath - The base directory of the extracted ICD-10-CM release (searched recursively for the tabular XML and order file)
# + version - The version to record for the imported CodeSystem, if given
# + return - The assembled `Icd10cmImportBundle`, or an `error` if a required release file is missing or cannot be read
public isolated function buildIcd10cmImport(string dirPath, string? version) returns Icd10cmImportBundle|error {
    string tabularPath = check findIcd10cmFile(dirPath, TABULAR_XML_MUST_CONTAIN, TABULAR_XML_EXTENSION);
    string orderFilePath = check findIcd10cmFile(dirPath, ORDER_FILE_MUST_CONTAIN, ORDER_FILE_EXTENSION, ORDER_FILE_MUST_NOT_CONTAIN);

    TabularIndex tabular = check parseTabularXml(tabularPath);
    [OrderFileRow[], int] orderResult = check streamOrderFile(orderFilePath);
    OrderFileRow[] orderRows = orderResult[0];
    int orderFileRowsRead = orderResult[1];

    IcdConceptImport[] chapterConcepts = [];
    foreach [string, string] [chapterName, chapterDesc] in tabular.chapterDescByName.entries() {
        chapterConcepts.push({
            code: CHAPTER_ID_PREFIX + chapterName,
            display: chapterDesc,
            parentCode: (),
            billable: false,
            sortGroup: SORT_GROUP_CHAPTER
        });
    }

    IcdConceptImport[] sectionConcepts = [];
    foreach TabularSection section in tabular.sections {
        sectionConcepts.push({
            code: SECTION_ID_PREFIX + section.id,
            display: section.desc,
            parentCode: CHAPTER_ID_PREFIX + section.chapterName,
            billable: false,
            sortGroup: SORT_GROUP_SECTION
        });
    }

    // Raw codes known to actually exist in the order file - used below to
    // skip placeholder "X" levels when resolving a code's parent.
    map<boolean> knownRawCodes = {};
    foreach OrderFileRow row in orderRows {
        knownRawCodes[row.rawCode] = true;
    }

    int maxRawLength = 0;
    IcdConceptImport[] codeConcepts = [];
    foreach OrderFileRow row in orderRows {
        int rawLength = row.rawCode.length();
        if rawLength > maxRawLength {
            maxRawLength = rawLength;
        }

        string? parentCode;
        if rawLength <= CATEGORY_CODE_LENGTH {
            string? sectionId = tabular.categoryToSectionId[row.code];
            // A category code with no known section is logged and left
            // parentless (becomes a root-level orphan) rather than failing
            // the whole import - this shouldn't happen for a well-formed
            // same-year release, but a single mismatched row must not block
            // the other ~98,700.
            parentCode = sectionId is string ? SECTION_ID_PREFIX + sectionId : ();
        } else {
            // Drop trailing characters until landing on a raw code that
            // actually exists in the order file - a single drop can land on
            // a placeholder "X" filler position that was never a 
            // real code, whose real parent is one or more levels further up.
            string parentRawCode = row.rawCode.substring(0, rawLength - 1);
            while parentRawCode.length() > CATEGORY_CODE_LENGTH && !knownRawCodes.hasKey(parentRawCode) {
                parentRawCode = parentRawCode.substring(0, parentRawCode.length() - 1);
            }
            parentCode = formatIcd10cmCode(parentRawCode);
        }

        codeConcepts.push({
            code: row.code,
            display: row.display,
            parentCode: parentCode,
            billable: row.billable,
            sortGroup: rawLength
        });
    }

    // Topological order: chapters, then sections, then order-file codes
    // grouped by raw length ascending - a code's parent is always either a
    // chapter/section (already placed first) or a shorter code (placed in an
    // earlier group), so the DB writer can resolve `parentConceptId` in a
    // single forward pass with no second lookup pass.
    IcdConceptImport[] sortedConcepts = [...chapterConcepts, ...sectionConcepts];
    foreach int length in CATEGORY_CODE_LENGTH ... maxRawLength {
        foreach IcdConceptImport concept in codeConcepts {
            if concept.sortGroup == length {
                sortedConcepts.push(concept);
            }
        }
    }

    return {
        codeSystemMetadata: buildIcd10cmCodeSystemMetadata(version),
        concepts: sortedConcepts,
        chaptersRead: chapterConcepts.length(),
        sectionsRead: sectionConcepts.length(),
        orderFileRowsRead: orderFileRowsRead
    };
}

# Finds the ICD-10-CM release file matching the given name filter under a
# directory, searching recursively (release zips nest their files inside a
# subdirectory named after the download).
#
# + dirPath - The directory to search under
# + mustContain - A substring (case-insensitive) the file name must contain
# + extension - The file extension the file name must end with (e.g. ".txt")
# + mustNotContain - An optional substring (case-insensitive) the file name must NOT contain, used to tell the order file apart from its same-prefixed addenda file
# + return - The absolute path of the matching file, or an `error` if none was found or a directory could not be read
isolated function findIcd10cmFile(string dirPath, string mustContain, string extension, string mustNotContain = "") returns string|error {
    string? found = check searchIcd10cmFile(dirPath, mustContain, extension, mustNotContain);
    if found is string {
        return found;
    }
    return error(string `ICD-10-CM release file containing '${mustContain}' with extension '${extension}' not found under ${dirPath}`);
}

isolated function searchIcd10cmFile(string dirPath, string mustContain, string extension, string mustNotContain) returns string?|error {
    boolean exists = check file:test(dirPath, file:EXISTS);
    if !exists {
        return ();
    }
    file:MetaData[] entries = check file:readDir(dirPath);
    foreach file:MetaData entry in entries {
        string name = getBaseName(entry.absPath).toLowerAscii();
        if !entry.dir && name.includes(mustContain) && name.endsWith(extension)
                && (mustNotContain == "" || !name.includes(mustNotContain)) {
            return entry.absPath;
        }
    }
    foreach file:MetaData entry in entries {
        if entry.dir {
            string? nested = check searchIcd10cmFile(entry.absPath, mustContain, extension, mustNotContain);
            if nested is string {
                return nested;
            }
        }
    }
    return ();
}

# Returns the final path segment (file or directory name) of the given path, splitting on either forward or backward slashes.
#
# + path - The file or directory path
# + return - The last segment of the path
isolated function getBaseName(string path) returns string {
    int cut = -1;
    int? lastSlash = path.lastIndexOf("/");
    if lastSlash is int {
        cut = lastSlash;
    }
    int? lastBackslash = path.lastIndexOf("\\");
    if lastBackslash is int && lastBackslash > cut {
        cut = lastBackslash;
    }
    if cut >= 0 {
        return path.substring(cut + 1);
    }
    return path;
}
