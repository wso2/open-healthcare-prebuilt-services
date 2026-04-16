import { useState, useEffect } from 'react';
import ConsentPage from './ConsentPage';
import PatientPickerPage from './PatientPickerPage';

const consentProps = window.__CONSENT_PROPS__;

function readStoredPatient() {
  const stored = sessionStorage.getItem("selectedPatient");
  if (!stored) return null;
  sessionStorage.removeItem("selectedPatient");
  try { return JSON.parse(stored); } catch { return null; }
}

function isPractitioner(scimUser) {
  console.log("SCIM user data:", scimUser);
  const fhirUser = scimUser?.["urn:scim:schemas:extension:custom:User"]?.fhirUser ?? "";
  return typeof fhirUser === "string" && fhirUser.includes("Practitioner");
}

export default function App() {
  const [selectedPatient, setSelectedPatient] = useState(readStoredPatient);
  const [practitioner, setPractitioner] = useState(null); // null = loading, true/false = resolved

  const userId = consentProps?.user ?? "";

  useEffect(() => {
    if (!userId) {
      setPractitioner(false);
      return;
    }
    fetch(`/api/me?userId=${encodeURIComponent(userId)}`)
      .then((r) => r.ok ? r.json() : Promise.reject())
      .then((data) => setPractitioner(isPractitioner(data)))
      .catch(() => setPractitioner(false));
  }, [userId]);

  if (practitioner === null) {
    return null; // loading — render nothing until role is resolved
  }

  if (practitioner && !selectedPatient) {
    return (
      <PatientPickerPage
        {...(consentProps ?? {})}
        onProceed={(patient) => setSelectedPatient(patient)}
      />
    );
  }

  if (!consentProps) {
    return (
      <div style={{ fontFamily: 'monospace', padding: '2rem', color: '#d32f2f' }}>
        <strong>Missing consent props.</strong> This page must be served by the Ballerina consent service.
      </div>
    );
  }

  const additionalContext = selectedPatient ? [JSON.stringify(selectedPatient)] : [];
  return <ConsentPage {...consentProps} additionalContext={additionalContext} />;
}
