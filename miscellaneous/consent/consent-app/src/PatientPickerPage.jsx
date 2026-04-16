import { useState, useEffect } from "react";
import AppBar from "@oxygen-ui/react/AppBar";
import Avatar from "@oxygen-ui/react/Avatar";
import Box from "@oxygen-ui/react/Box";
import Button from "@oxygen-ui/react/Button";
import Card from "@oxygen-ui/react/Card";
import CardContent from "@oxygen-ui/react/CardContent";
import Chip from "@oxygen-ui/react/Chip";
import CircularProgress from "@oxygen-ui/react/CircularProgress";
import Divider from "@oxygen-ui/react/Divider";
import FormControl from "@oxygen-ui/react/FormControl";
import MenuItem from "@oxygen-ui/react/MenuItem";
import Select from "@oxygen-ui/react/Select";
import Toolbar from "@oxygen-ui/react/Toolbar";
import Typography from "@oxygen-ui/react/Typography";

// ─── Helpers ──────────────────────────────────────────────────────────────────
function formatDob(dob) {
  if (!dob) return "—";
  const d = new Date(dob);
  return d.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" });
}

function calcAge(dob) {
  if (!dob) return null;
  const today = new Date();
  const birth = new Date(dob);
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
  return age;
}

function getInitials(name) {
  if (!name) return "?";
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

// ─── Sub-components ───────────────────────────────────────────────────────────
function Wso2Logo() {
  return (
    <img
      src="https://wso2.cachefly.net/wso2/sites/all/image_resources/logos/WSO2-Logo-Black.webp"
      alt="WSO2"
      style={{ height: "28px", display: "block" }}
    />
  );
}

function ErrorBanner({ message }) {
  return (
    <Box
      sx={{
        p: 2,
        mb: 3,
        bgcolor: "#fff5f5",
        border: "1px solid #ffcdd2",
        borderRadius: 2,
      }}
    >
      <Typography variant="body2" sx={{ color: "#d32f2f", fontWeight: 600, mb: 0.5 }}>
        Something went wrong
      </Typography>
      <Typography variant="body2" sx={{ color: "#d32f2f" }}>
        {message}
      </Typography>
    </Box>
  );
}

function DetailRow({ label, value }) {
  return (
    <Box sx={{ display: "flex", gap: 1.5, alignItems: "flex-start", mb: 1 }}>
      <Typography
        variant="caption"
        sx={{
          color: "text.secondary",
          fontWeight: 600,
          textTransform: "uppercase",
          letterSpacing: "0.06em",
          minWidth: 90,
          pt: "2px",
        }}
      >
        {label}
      </Typography>
      <Typography variant="body2" sx={{ color: "text.primary" }}>
        {value || "—"}
      </Typography>
    </Box>
  );
}

// ─── PatientPickerPage ────────────────────────────────────────────────────────
function mapScimPatient(resource) {
  const givenName = resource.name?.givenName ?? "";
  const familyName = resource.name?.familyName ?? "";
  const name = [givenName, familyName].filter(Boolean).join(" ") || resource.userName || resource.id;
  const fhirUser = resource["urn:scim:schemas:extension:custom:User"]?.fhirUser ?? null;
  return {
    id: resource.id,
    name,
    mrn: resource.userName ?? null,
    fhirUser,
    dob: null,
    gender: null,
    phone: null,
    address: null,
    bloodType: null,
  };
}

function mapScimUser(scim) {
  const givenName = scim.name?.givenName ?? "";
  const familyName = scim.name?.familyName ?? "";
  const displayName = [givenName, familyName].filter(Boolean).join(" ") || scim.userName;
  const workEmail = scim.emails?.find((e) => e.type === "work")?.value;
  const email = workEmail ?? scim.emails?.[0]?.value ?? "";
  const roles = (scim.roles ?? []).map((r) => r.value);
  return { username: scim.userName, displayName, email, roles };
}

export default function PatientPickerPage({ onProceed, onCancel, sessionDataKeyConsent, spId, user: userId }) {
  const [user, setUser] = useState(null);
  const [patients, setPatients] = useState([]);
  const [selectedId, setSelectedId] = useState("");
  const [loading, setLoading] = useState(true);
  const [userError, setUserError] = useState(null);
  const [patientsError, setPatientsError] = useState(null);

  useEffect(() => {
    const userPromise = fetch(`/api/me?userId=${encodeURIComponent(userId ?? "")}`)
      .then((r) => {
        if (r.status === 400) throw new Error("User ID is missing or invalid.");
        if (r.status === 502) throw new Error("Could not reach the identity server to load user details.");
        if (!r.ok) throw new Error(`Failed to load user details (HTTP ${r.status}).`);
        return r.json();
      })
      .then(mapScimUser)
      .catch((err) => { setUserError(err.message); return null; });

    const patientsPromise = fetch("/api/patients")
      .then((r) => {
        if (r.status === 502) throw new Error("Could not reach the identity server to load patient list.");
        if (!r.ok) throw new Error(`Failed to load patient list (HTTP ${r.status}).`);
        return r.json();
      })
      .then((data) => {
        const resources = Array.isArray(data.Resources) ? data.Resources : [];
        if (resources.length === 0) throw new Error("No patients found matching the required criteria.");
        return resources.map(mapScimPatient);
      })
      .catch((err) => { setPatientsError(err.message); return []; });

    Promise.all([userPromise, patientsPromise]).then(([userData, patientsData]) => {
      if (userData) setUser(userData);
      setPatients(patientsData);
      setLoading(false);
    });
  }, []);

  const selectedPatient = patients.find((p) => p.id === selectedId) ?? null;

  const handleProceed = () => {
    if (onProceed) {
      onProceed(selectedPatient);
      return;
    }
    if (selectedPatient) {
      sessionStorage.setItem("selectedPatient", JSON.stringify(selectedPatient));
    }
    const params = new URLSearchParams();
    if (sessionDataKeyConsent) params.set("sessionDataKeyConsent", sessionDataKeyConsent);
    if (spId) params.set("spId", spId);
    window.location.href = "/consent?" + params.toString();
  };

  const handleCancel = () => {
    if (onCancel) {
      onCancel();
      return;
    }
    window.history.back();
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        backgroundColor: "#f5f5f5",
        fontFamily: "'Nunito Sans', 'Segoe UI', Helvetica, Arial, sans-serif",
      }}
    >
      {/* ── Header ─────────────────────────────────────────────────────────── */}
      <AppBar
        position="static"
        elevation={0}
        sx={{
          backgroundColor: "#ffffff",
          borderBottom: "1px solid #e0e0e0",
          color: "inherit",
        }}
      >
        <Toolbar sx={{ gap: 1.5, px: { xs: 2, sm: 4 } }}>
          <Wso2Logo />
          <Typography
            sx={{
              fontSize: "15px",
              fontWeight: 400,
              letterSpacing: "0.04em",
              color: "#1a1a2e",
              flexGrow: 1,
            }}
          >
            OPEN HEALTHCARE
          </Typography>

          {/* Logged-in user info */}
          {user && (
            <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              <Avatar
                sx={{
                  width: 32,
                  height: 32,
                  fontSize: "13px",
                  bgcolor: "#3B3B8F",
                  fontWeight: 700,
                }}
              >
                {getInitials(user.displayName || user.username)}
              </Avatar>
              <Box sx={{ display: { xs: "none", sm: "block" } }}>
                <Typography variant="body2" sx={{ fontWeight: 600, color: "#1a1a2e", lineHeight: 1.2 }}>
                  {user.displayName || user.username}
                </Typography>
                {user.email && (
                  <Typography variant="caption" sx={{ color: "#5a5a72" }}>
                    {user.email}
                  </Typography>
                )}
              </Box>
            </Box>
          )}
        </Toolbar>
      </AppBar>

      {/* ── Main ───────────────────────────────────────────────────────────── */}
      <Box
        component="main"
        sx={{
          flex: 1,
          display: "flex",
          justifyContent: "center",
          alignItems: "flex-start",
          p: { xs: 2, sm: "40px 16px 60px" },
        }}
      >
        <Card
          elevation={2}
          sx={{
            width: "100%",
            maxWidth: 560,
            borderRadius: "12px",
            border: "1px solid #e0e0e0",
          }}
        >
          <CardContent sx={{ p: { xs: 3, sm: "36px 40px 32px" } }}>
            {/* Title */}
            <Typography
              variant="h5"
              sx={{
                fontWeight: 700,
                color: "#1a1a2e",
                letterSpacing: "-0.02em",
                mb: 0.5,
              }}
            >
              Select Patient
            </Typography>
            <Typography variant="body2" sx={{ color: "#5a5a72", mb: 3 }}>
              Choose the patient record you want to associate with this session.
            </Typography>

            {/* Loading state */}
            {loading && (
              <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
                <CircularProgress size={36} sx={{ color: "#3B3B8F" }} />
              </Box>
            )}

            {/* Error banners */}
            {!loading && userError && <ErrorBanner message={userError} />}
            {!loading && patientsError && <ErrorBanner message={patientsError} />}

            {/* Meta badges */}
            {!loading && (
              <Box sx={{ display: "flex", flexWrap: "wrap", gap: 1, mb: 3 }}>
                {user && (
                  <Chip
                    label={`Practitioner: ${user.displayName || user.username}`}
                    size="small"
                    sx={{
                      bgcolor: "#eeeeff",
                      color: "#3B3B8F",
                      fontWeight: 600,
                      fontSize: "11px",
                      letterSpacing: "0.03em",
                    }}
                  />
                )}
                {!patientsError && (
                  <Chip
                    label={`${patients.length} patient${patients.length !== 1 ? "s" : ""} available`}
                    size="small"
                    sx={{
                      bgcolor: "#f0faf0",
                      color: "#2e7d32",
                      fontWeight: 600,
                      fontSize: "11px",
                    }}
                  />
                )}
              </Box>
            )}

            {/* Patient dropdown — only when patients loaded successfully */}
            {!loading && !patientsError && (
              <>
                <Typography
                  variant="caption"
                  sx={{
                    fontWeight: 700,
                    textTransform: "uppercase",
                    letterSpacing: "0.08em",
                    color: "#9090a8",
                    display: "block",
                    mb: 1,
                  }}
                >
                  Patient
                </Typography>
                <FormControl fullWidth size="small" sx={{ mb: 3 }}>
                  <Select
                    value={selectedId}
                    displayEmpty
                    renderValue={(value) =>
                      value
                        ? patients.find((p) => p.id === value)?.name ?? value
                        : <span style={{ color: "rgba(0,0,0,0.42)" }}>Choose a patient…</span>
                    }
                    onChange={(e) => setSelectedId(e.target.value)}
                    sx={{ borderRadius: "8px" }}
                  >
                    {patients.map((p) => (
                      <MenuItem key={p.id} value={p.id}>
                        <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                          <Avatar
                            sx={{
                              width: 28,
                              height: 28,
                              fontSize: "11px",
                              bgcolor: "#3B3B8F",
                              fontWeight: 700,
                            }}
                          >
                            {getInitials(p.name)}
                          </Avatar>
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: 1.2 }}>
                              {p.name}
                            </Typography>
                            <Typography variant="caption" sx={{ color: "#5a5a72" }}>
                              {p.mrn}
                            </Typography>
                          </Box>
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                {/* Selected patient details card */}
                {selectedPatient && (
                  <Box
                    sx={{
                      border: "1px solid #e0e0e0",
                      borderRadius: "8px",
                      bgcolor: "#f8f8fc",
                      p: 2,
                      mb: 3,
                    }}
                  >
                    <Box sx={{ display: "flex", alignItems: "center", gap: 2, mb: 2 }}>
                      <Avatar
                        sx={{
                          width: 48,
                          height: 48,
                          fontSize: "18px",
                          bgcolor: "#3B3B8F",
                          fontWeight: 700,
                        }}
                      >
                        {getInitials(selectedPatient.name)}
                      </Avatar>
                      <Box>
                        <Typography variant="subtitle1" sx={{ fontWeight: 700, color: "#1a1a2e" }}>
                          {selectedPatient.name}
                        </Typography>
                        <Typography variant="caption" sx={{ color: "#5a5a72" }}>
                          {selectedPatient.mrn}
                        </Typography>
                      </Box>
                    </Box>

                    <Divider sx={{ mb: 1.5 }} />

                    {selectedPatient.dob && (
                      <DetailRow
                        label="Date of Birth"
                        value={`${formatDob(selectedPatient.dob)} (Age ${calcAge(selectedPatient.dob)})`}
                      />
                    )}
                    {selectedPatient.gender && (
                      <DetailRow label="Gender" value={selectedPatient.gender} />
                    )}
                    {selectedPatient.bloodType && (
                      <DetailRow label="Blood Type" value={selectedPatient.bloodType} />
                    )}
                    {selectedPatient.phone && (
                      <DetailRow label="Phone" value={selectedPatient.phone} />
                    )}
                    {selectedPatient.address && (
                      <DetailRow label="Address" value={selectedPatient.address} />
                    )}
                    {selectedPatient.fhirUser && (
                      <DetailRow label="FHIR User" value={selectedPatient.fhirUser} />
                    )}
                  </Box>
                )}

                <Divider sx={{ mb: 3 }} />

                {/* Action buttons */}
                <Box sx={{ display: "flex", gap: 1.5 }}>
                  <Button
                    variant="contained"
                    fullWidth
                    disabled={!selectedPatient}
                    onClick={handleProceed}
                    sx={{
                      bgcolor: "#3B3B8F",
                      fontWeight: 700,
                      fontSize: "15px",
                      py: 1.5,
                      borderRadius: "8px",
                      letterSpacing: "0.01em",
                      textTransform: "none",
                      "&:hover": { bgcolor: "#2d2d7a" },
                      "&.Mui-disabled": {
                        bgcolor: "#c5c5e0",
                        color: "#ffffff",
                      },
                    }}
                  >
                    Proceed
                  </Button>
                  <Button
                    variant="outlined"
                    onClick={handleCancel}
                    sx={{
                      color: "#d32f2f",
                      borderColor: "#d32f2f",
                      fontWeight: 600,
                      fontSize: "15px",
                      py: 1.5,
                      px: 3,
                      borderRadius: "8px",
                      textTransform: "none",
                      "&:hover": {
                        bgcolor: "#fff5f5",
                        borderColor: "#d32f2f",
                      },
                    }}
                  >
                    Cancel
                  </Button>
                </Box>
              </>
            )}

            {/* Cancel-only fallback when patients failed to load */}
            {!loading && patientsError && (
              <Box sx={{ display: "flex", gap: 1.5, mt: 1 }}>
                <Button
                  variant="outlined"
                  onClick={handleCancel}
                  sx={{
                    color: "#d32f2f",
                    borderColor: "#d32f2f",
                    fontWeight: 600,
                    fontSize: "15px",
                    py: 1.5,
                    px: 3,
                    borderRadius: "8px",
                    textTransform: "none",
                    "&:hover": { bgcolor: "#fff5f5", borderColor: "#d32f2f" },
                  }}
                >
                  Cancel
                </Button>
              </Box>
            )}
          </CardContent>
        </Card>
      </Box>

      {/* ── Footer ─────────────────────────────────────────────────────────── */}
      <Box
        component="footer"
        sx={{
          textAlign: "center",
          py: 2,
          px: 2,
          fontSize: "12px",
          color: "#9090a8",
          borderTop: "1px solid #e0e0e0",
          bgcolor: "#ffffff",
        }}
      >
        <Typography variant="caption" sx={{ color: "#9090a8" }}>
          WSO2 Healthcare | © {new Date().getFullYear()}
        </Typography>
      </Box>
    </Box>
  );
}
