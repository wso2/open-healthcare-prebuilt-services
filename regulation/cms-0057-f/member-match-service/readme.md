# Ballerina Pre-built Service for $member-match Operation

This pre-built service implements the FHIR PDex `$member-match` operation, enabling member matching functionality on top of an existing FHIR server and FHIR consent service. It can be integrated to facilitate seamless data exchange between payers as part of the DaVinci Payer Data Exchange (PDex) workflow.

## Features
- Implements the FHIR PDex `$member-match` operation for payer-to-payer data exchange.
- Supports integration with existing FHIR servers and consent services.
- Customizable member matching logic via an extension point.
- Ensures compliance with FHIR PDex and US Core profiles for accurate member identification.

## Endpoints

### 1. Member Match
Matches members based on patient demographic data across different payers.

**Endpoint**:  
`POST /fhir/r4/Patient/$member-match`

**Request Body**:  
FHIR-compliant demographic data of the patient for matching purposes.

**Response**:  
- Returns the FHIR Patient resource if a match is found, or an appropriate error message if no match is found.


## How it Works
1. The service receives a `$member-match` request from a new payer, which includes patient demographic information.
2. The service validates the request and checks for matching patient records in the existing FHIR server.
3. Consent is verified (if applicable) by interacting with the integrated FHIR consent service.
4. Upon a successful match, the FHIR Patient resource is returned to the requesting payer.

## Customization
The service comes with a default member matching logic, but you can implement your own by leveraging the built-in extension point. Simply develop a custom matcher by implementing `*davincihrex100:MemberMatcher` and update the matcher instantiation with the newly developed matcher.

```
final DemoFHIRMemberMatcher fhirMemberMatcher = check new ();

davincihrex100:MemberIdentifier memberIdentifier = check fhirMemberMatcher.matchMember(memberMatchResources);
```

## Prerequisites
- An operational FHIR server compliant with US Core profiles.
- A FHIR consent service (optional) to validate patient consent before exchanging data.

## How to Run
1. Clone the repository.
2. Configure the FHIR server and consent service endpoints in the environment variables.
3. Deploy the service alongside your FHIR server.
4. Use the provided API endpoints to enable member matching for payer-to-payer exchanges.

## Example Request

```json
POST /Patient/$member-match
{
    "resourceType": "Parameters",
    "parameter": [
        {
            "resource": {
                "resourceType": "Patient",
                "extension": [
                    {
                        "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race",
                        "extension": [
                            {
                                "url": "ombCategory",
                                "valueCoding": {
                                    "system": "urn:oid:2.16.840.1.113883.6.238",
                                    "code": "2106-3",
                                    "display": "White"
                                }
                            },
                            {
                                "url": "text",
                                "valueString": "Mixed"
                            }
                        ]
                    },
                    {
                        "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity",
                        "extension": [
                            {
                                "url": "ombCategory",
                                "valueCoding": {
                                    "system": "urn:oid:2.16.840.1.113883.6.238",
                                    "code": "2135-2",
                                    "display": "Hispanic or Latino"
                                }
                            },
                            {
                                "url": "text",
                                "valueString": "Hispanic or Latino"
                            }
                        ]
                    },
                    {
                        "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
                        "valueCode": "F"
                    },
                    {
                        "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-genderIdentity",
                        "valueCodeableConcept": {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
                                    "code": "ASKU",
                                    "display": "asked but unknown"
                                }
                            ],
                            "text": "asked but unknown"
                        }
                    }
                ],
                "gender": "female",
                "telecom": [
                    {
                        "system": "phone",
                        "use": "home",
                        "value": "555-555-5555"
                    },
                    {
                        "system": "email",
                        "value": "amy.shaw@example.com"
                    }
                ],
                "id": "patient-1",
                "identifier": [
                    {
                        "system": "http://hospital.smarthealthit.org",
                        "use": "usual",
                        "type": {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/v2-0203",
                                    "code": "MR",
                                    "display": "Medical Record Number"
                                }
                            ],
                            "text": "Medical Record Number"
                        },
                        "value": "1032702"
                    }
                ],
                "address": [
                    {
                        "country": "US",
                        "period": {
                            "start": "2020-07-22"
                        },
                        "city": "Mounds",
                        "line": [
                            "183 Mountain View St"
                        ],
                        "postalCode": "74048",
                        "state": "OK"
                    }
                ],
                "birthDate": "1987-02-20",
                "meta": {
                    "versionId": "1",
                    "lastUpdated": "2021-06-01T00:00:00Z",
                    "profile": [
                        "http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"
                    ]
                },
                "name": [
                    {
                        "given": [
                            "Cortez",
                            "V."
                        ],
                        "period": {
                            "start": "2020-07-22"
                        },
                        "family": "Prohaska",
                        "suffix": [
                            "PharmD"
                        ]
                    }
                ],
                "implicitRules": "https://example.com/base"
            },
            "name": "MemberPatient"
        },
        {
            "resource": {
                "resourceType": "Coverage",
                "payor": [
                    {
                        "identifier": {
                            "system": "http://hl7.org/fhir/sid/us-npi",
                            "value": "9876543210"
                        },
                        "display": "Old Health Plan"
                    }
                ],
                "id": "coverage-1",
                "class": [
                    {
                        "type": {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/coverage-class",
                                    "code": "group"
                                }
                            ]
                        },
                        "value": "CB135"
                    }
                ],
                "period": {
                    "start": "2011-05-23",
                    "end": "2012-05-23"
                },
                "beneficiary": {
                    "reference": "Patient/736a19c8-eea5-32c5-67ad-1947661de21a"
                },
                "meta": {
                    "versionId": "1",
                    "lastUpdated": "2021-06-01T00:00:00Z"
                },
                "implicitRules": "https://example.com/base",
                "status": "entered-in-error"
            },
            "name": "CoverageToMatch"
        },
        {
            "resource": {
                "resourceType": "Coverage",
                "payor": [
                    {
                        "identifier": {
                            "system": "http://hl7.org/fhir/sid/us-npi",
                            "value": "0123456789"
                        },
                        "display": "New Health Plan"
                    }
                ],
                "id": "cAA87654",
                "period": {
                    "start": "2011-05-23",
                    "end": "2012-05-23"
                },
                "beneficiary": {
                    "reference": "Patient/patient-1"
                },
                "meta": {
                    "versionId": "1",
                    "lastUpdated": "2021-06-01T00:00:00Z"
                },
                "implicitRules": "https://example.com/base",
                "status": "active"
            },
            "name": "CoverageToLink"
        },
        {
            "resource": {
                "resourceType": "Consent",
                "status": "active",
                "scope": {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/consentscope",
                            "code": "patient-privacy"
                        }
                    ]
                },
                "category": [
                    {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                                "code": "IDSCL"
                            }
                        ]
                    }
                ],
                "patient": {
                    "reference": "Patient/patient-1"
                },
                "performer": [
                    {
                        "reference": "http://example.org/Patient/example"
                    }
                ],
                "sourceReference": {
                    "reference": "http://example.org/DocumentReference/someconsent"
                },
                "policy": [
                    {
                        "uri": "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#regular"
                    }
                ],
                "provision": {
                    "type": "permit",
                    "period": {
                        "start": "2022-01-01",
                        "end": "2022-01-31"
                    },
                    "actor": [
                        {
                            "role": {
                                "coding": [
                                    {
                                        "system": "http://terminology.hl7.org/CodeSystem/provenance-participant-type",
                                        "code": "performer"
                                    }
                                ]
                            },
                            "reference": {
                                "identifier": {
                                    "system": "http://hl7.org/fhir/sid/us-npi",
                                    "value": "9876543210"
                                },
                                "display": "Old Health Plan"
                            }
                        }
                    ],
                    "action": [
                        {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/consentaction",
                                    "code": "disclose"
                                }
                            ]
                        }
                    ]
                }
            },
            "name": "Consent"
        }
    ],
    "id": "member-match-in"
}
```
