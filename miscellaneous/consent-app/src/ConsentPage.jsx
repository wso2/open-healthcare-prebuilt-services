import { useState, useCallback } from "react";

// ─── WSO2 Open Healthcare theme tokens (matching the sign-in page) ───────────
const theme = {
  primary: "#3B3B8F",       // deep indigo – the "Continue" button
  primaryHover: "#2d2d7a",
  primaryLight: "#eeeeff",
  accent: "#F47B20",        // WSO2 orange (logo)
  surface: "#ffffff",
  background: "#f5f5f5",
  border: "#e0e0e0",
  textPrimary: "#1a1a2e",
  textSecondary: "#5a5a72",
  textMuted: "#9090a8",
  danger: "#d32f2f",
  dangerLight: "#fff5f5",
  success: "#2e7d32",
  successLight: "#f0faf0",
  radius: "8px",
  radiusLg: "12px",
  shadow: "0 2px 16px rgba(59,59,143,0.10)",
  shadowCard: "0 1px 4px rgba(0,0,0,0.08)",
};

// ─── Inline styles ─────────────────────────────────────────────────────────────
const styles = {
  page: {
    minHeight: "100vh",
    background: theme.background,
    fontFamily: "'Nunito Sans', 'Segoe UI', Helvetica, Arial, sans-serif",
    display: "flex",
    flexDirection: "column",
  },
  header: {
    background: theme.surface,
    borderBottom: `1px solid ${theme.border}`,
    padding: "14px 32px",
    display: "flex",
    alignItems: "center",
    gap: "10px",
  },
  logoText: {
    fontSize: "18px",
    fontWeight: 700,
    letterSpacing: "0.04em",
    color: theme.textPrimary,
  },
  logoAccent: { color: theme.accent },
  main: {
    flex: 1,
    display: "flex",
    justifyContent: "center",
    alignItems: "flex-start",
    padding: "40px 16px 60px",
  },
  card: {
    background: theme.surface,
    borderRadius: theme.radiusLg,
    boxShadow: theme.shadow,
    width: "100%",
    maxWidth: "560px",
    padding: "36px 40px 32px",
    border: `1px solid ${theme.border}`,
  },
  cardTitle: {
    margin: "0 0 4px",
    fontSize: "22px",
    fontWeight: 700,
    color: theme.textPrimary,
    letterSpacing: "-0.02em",
  },
  cardSubtitle: {
    margin: "0 0 24px",
    fontSize: "13px",
    color: theme.textSecondary,
  },
  metaRow: {
    display: "flex",
    gap: "8px",
    marginBottom: "20px",
    flexWrap: "wrap",
  },
  metaBadge: {
    background: theme.primaryLight,
    color: theme.primary,
    fontSize: "11px",
    fontWeight: 600,
    borderRadius: "4px",
    padding: "3px 8px",
    letterSpacing: "0.03em",
  },
  sectionLabel: {
    fontSize: "12px",
    fontWeight: 700,
    textTransform: "uppercase",
    letterSpacing: "0.08em",
    color: theme.textMuted,
    marginBottom: "10px",
  },
  scopeList: {
    border: `1px solid ${theme.border}`,
    borderRadius: theme.radius,
    overflow: "hidden",
    marginBottom: "20px",
  },
  scopeItem: (checked, last) => ({
    display: "flex",
    alignItems: "center",
    gap: "12px",
    padding: "12px 16px",
    borderBottom: last ? "none" : `1px solid ${theme.border}`,
    background: checked ? theme.primaryLight : theme.surface,
    transition: "background 0.15s",
    cursor: "pointer",
  }),
  checkbox: {
    width: "17px",
    height: "17px",
    accentColor: theme.primary,
    cursor: "pointer",
    flexShrink: 0,
  },
  scopeLabel: (checked) => ({
    fontSize: "14px",
    color: checked ? theme.primary : theme.textPrimary,
    fontWeight: checked ? 600 : 400,
    fontFamily: "'Fira Code', 'Courier New', monospace",
    wordBreak: "break-all",
  }),
  emptyState: {
    padding: "16px",
    color: theme.textMuted,
    fontSize: "14px",
    textAlign: "center",
  },
  bulkRow: {
    display: "flex",
    gap: "8px",
    marginBottom: "24px",
  },
  ghostBtn: {
    background: "transparent",
    border: `1px solid ${theme.border}`,
    borderRadius: theme.radius,
    padding: "7px 14px",
    fontSize: "13px",
    color: theme.textSecondary,
    cursor: "pointer",
    fontFamily: "inherit",
    transition: "border-color 0.15s, color 0.15s",
  },
  divider: {
    border: "none",
    borderTop: `1px solid ${theme.border}`,
    margin: "0 0 24px",
  },
  actionRow: {
    display: "flex",
    gap: "12px",
  },
  approveBtn: {
    flex: 1,
    background: theme.primary,
    color: "#fff",
    border: "none",
    borderRadius: theme.radius,
    padding: "12px 20px",
    fontSize: "15px",
    fontWeight: 700,
    cursor: "pointer",
    fontFamily: "inherit",
    letterSpacing: "0.01em",
    transition: "background 0.15s",
  },
  denyBtn: {
    background: "transparent",
    color: theme.danger,
    border: `1px solid ${theme.danger}`,
    borderRadius: theme.radius,
    padding: "12px 20px",
    fontSize: "15px",
    fontWeight: 600,
    cursor: "pointer",
    fontFamily: "inherit",
    transition: "background 0.15s, color 0.15s",
  },
  contextToggle: {
    marginTop: "20px",
    fontSize: "12px",
    color: theme.primary,
    cursor: "pointer",
    userSelect: "none",
    display: "inline-flex",
    alignItems: "center",
    gap: "4px",
    fontWeight: 600,
  },
  contextBox: {
    marginTop: "10px",
    background: "#f8f8fc",
    border: `1px solid ${theme.border}`,
    borderRadius: theme.radius,
    padding: "14px 16px",
    fontSize: "12px",
    fontFamily: "'Fira Code', 'Courier New', monospace",
    color: theme.textSecondary,
    whiteSpace: "pre-wrap",
    wordBreak: "break-all",
    maxHeight: "200px",
    overflowY: "auto",
  },
  footer: {
    textAlign: "center",
    padding: "16px",
    fontSize: "12px",
    color: theme.textMuted,
    borderTop: `1px solid ${theme.border}`,
    background: theme.surface,
  },
};

// ─── WSO2 Logo ────────────────────────────────────────────────────────────────
function Wso2Logo() {
  return (
    <img
      src="https://wso2.cachefly.net/wso2/sites/all/image_resources/logos/WSO2-Logo-Black.webp"
      alt="WSO2"
      style={{ height: "28px", display: "block" }}
    />
  );
}

// ─── ConsentPage component ─────────────────────────────────────────────────────
export default function ConsentPage({
  sessionDataKeyConsent,
  spId,
  user,
  scopes = [],
  onApprove,
  onDeny,
}) {
  // Validate SMART scopes: if it starts with patient/user/system/ it must match the full regex
  const scopeRegex = /^(patient|user|system)\/(\*|[A-Za-z]*)\.(cruds|c?r?u?d?s?)$/;
  const isValidScope = (s) => {
    if (/^(patient|user|system)\//.test(s)) return scopeRegex.test(s);
    return true;
  };

  // Split scopes: hidden (OH_launch/) vs selectable; drop invalid SMART scopes
  const hiddenScopes = scopes.filter((s) => s.startsWith("OH_launch/"));
  const selectableScopes = scopes
    .filter((s) => !s.startsWith("OH_launch/"))
    .filter(isValidScope);

  const [checked, setChecked] = useState(() =>
    Object.fromEntries(selectableScopes.map((s) => [s, true]))
  );
  const [approveHover, setApproveHover] = useState(false);
  const [denyHover, setDenyHover] = useState(false);

  const toggleScope = useCallback((scope) => {
    setChecked((prev) => ({ ...prev, [scope]: !prev[scope] }));
  }, []);

  const toggleAll = useCallback((val) => {
    setChecked(Object.fromEntries(selectableScopes.map((s) => [s, val])));
  }, [selectableScopes]);

  const selectedScopes = selectableScopes.filter((s) => checked[s]);

  const handleApprove = () => {
    if (onApprove) {
      onApprove({ sessionDataKeyConsent, spId, user, scopes: [...selectedScopes, ...hiddenScopes] });
      return;
    }
    // Real form submission
    const form = document.createElement("form");
    form.method = "post";
    form.action = "/consent";
    const fields = {
      SessionDataKeyConsent: sessionDataKeyConsent,
      spId,
      user,
      Consent: "approve",
      hasApprovedAlways: "false",
      User_claims_consent: "true",
    };
    Object.entries(fields).forEach(([k, v]) => {
      const el = document.createElement("input");
      el.type = "hidden"; el.name = k; el.value = v;
      form.appendChild(el);
    });
    [...selectedScopes, ...hiddenScopes].forEach((s) => {
      const el = document.createElement("input");
      el.type = "hidden"; el.name = "scope"; el.value = s;
      form.appendChild(el);
    });
    document.body.appendChild(form);
    form.submit();
  };

  const handleDeny = () => {
    if (onDeny) { onDeny(); return; }
    const form = document.createElement("form");
    form.method = "post";
    form.action = "/consent";
    const fields = {
      SessionDataKeyConsent: sessionDataKeyConsent,
      Consent: "deny",
      hasApprovedAlways: "false",
      User_claims_consent: "true",
      spId,
      user,
    };
    Object.entries(fields).forEach(([k, v]) => {
      const el = document.createElement("input");
      el.type = "hidden"; el.name = k; el.value = v;
      form.appendChild(el);
    });
    document.body.appendChild(form);
    form.submit();
  };

  return (
    <div style={styles.page}>
      {/* Header */}
      <header style={styles.header}>
        <Wso2Logo />
        <span style={{ fontSize: "15px", fontWeight: 400, color: theme.textPrimary, letterSpacing: "0.04em" }}>
          OPEN HEALTHCARE
        </span>
      </header>

      {/* Main content */}
      <main style={styles.main}>
        <div style={styles.card}>
          <h1 style={styles.cardTitle}>Authorize Access</h1>
          <p style={styles.cardSubtitle}>
            Review and approve the permissions requested by this application.
          </p>

          {/* Meta badges */}
          <div style={styles.metaRow}>
            <span style={styles.metaBadge}>👤 {user}</span>
          </div>

          {/* Selectable scopes */}
          {selectableScopes.length > 0 ? (
            <>
              <div style={styles.sectionLabel}>Requested Permissions</div>
              <div style={styles.scopeList}>
                {selectableScopes.map((scope, i) => {
                  const isChecked = !!checked[scope];
                  const isLast = i === selectableScopes.length - 1;
                  return (
                    <div
                      key={scope}
                      style={styles.scopeItem(isChecked, isLast)}
                      onClick={() => toggleScope(scope)}
                    >
                      <input
                        type="checkbox"
                        style={styles.checkbox}
                        checked={isChecked}
                        onChange={() => toggleScope(scope)}
                        onClick={(e) => e.stopPropagation()}
                      />
                      <span style={styles.scopeLabel(isChecked)}>{scope}</span>
                    </div>
                  );
                })}
              </div>

              {/* Bulk controls */}
              <div style={styles.bulkRow}>
                <button style={styles.ghostBtn} onClick={() => toggleAll(true)}>
                  ✓ Select all
                </button>
                <button style={styles.ghostBtn} onClick={() => toggleAll(false)}>
                  ✕ Clear all
                </button>
                <span style={{ marginLeft: "auto", fontSize: "12px", color: theme.textMuted, alignSelf: "center" }}>
                  {selectedScopes.length}/{selectableScopes.length} selected
                </span>
              </div>
            </>
          ) : (
            <div style={styles.scopeList}>
              <div style={styles.emptyState}>No selectable permissions found.</div>
            </div>
          )}

          <hr style={styles.divider} />

          {/* Actions */}
          <div style={styles.actionRow}>
            <button
              style={{
                ...styles.approveBtn,
                background: approveHover ? theme.primaryHover : theme.primary,
              }}
              onMouseEnter={() => setApproveHover(true)}
              onMouseLeave={() => setApproveHover(false)}
              onClick={handleApprove}
            >
              Approve
            </button>
            <button
              style={{
                ...styles.denyBtn,
                background: denyHover ? theme.dangerLight : "transparent",
              }}
              onMouseEnter={() => setDenyHover(true)}
              onMouseLeave={() => setDenyHover(false)}
              onClick={handleDeny}
            >
              Deny
            </button>
          </div>

        </div>
      </main>

      {/* Footer */}
      <footer style={styles.footer}>WSO2 Healthcare | © {new Date().getFullYear()}</footer>
    </div>
  );
}
