import { useState, useCallback } from "react";
import "./ConsentPage.css";

// ─── WSO2 Logo ────────────────────────────────────────────────────────────────
function Wso2Logo() {
  return (
    <img
      src="https://wso2.cachefly.net/wso2/sites/all/image_resources/logos/WSO2-Logo-Black.webp"
      alt="WSO2"
      className="wso2-logo"
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
    <div className="consent-page">
      {/* Header */}
      <header className="consent-header">
        <Wso2Logo />
        <span className="header-subtitle">
          OPEN HEALTHCARE
        </span>
      </header>

      {/* Main content */}
      <main className="consent-main">
        <div className="consent-card">
          <h1 className="card-title">Authorize Access</h1>
          <p className="card-subtitle">
            Review and approve the permissions requested by this application.
          </p>

          {/* Meta badges */}
          <div className="meta-row">
            <span className="meta-badge">👤 {user}</span>
          </div>

          {/* Selectable scopes */}
          {selectableScopes.length > 0 ? (
            <>
              <div className="section-label">Requested Permissions</div>
              <div className="scope-list">
                {selectableScopes.map((scope, i) => {
                  const isChecked = !!checked[scope];
                  const isLast = i === selectableScopes.length - 1;
                  return (
                    <div
                      key={scope}
                      className={`scope-item ${isChecked ? "checked" : ""} ${isLast ? "last" : ""}`.trim()}
                      onClick={() => toggleScope(scope)}
                    >
                      <input
                        type="checkbox"
                        className="scope-checkbox"
                        checked={isChecked}
                        onChange={() => toggleScope(scope)}
                        onClick={(e) => e.stopPropagation()}
                      />
                      <span className={`scope-label ${isChecked ? "checked" : ""}`.trim()}>{scope}</span>
                    </div>
                  );
                })}
              </div>

              {/* Bulk controls */}
              <div className="bulk-row">
                <button type="button" className="ghost-btn" onClick={() => toggleAll(true)}>
                  ✓ Select all
                </button>
                <button type="button" className="ghost-btn" onClick={() => toggleAll(false)}>
                  ✕ Clear all
                </button>
                <span className="selection-count">
                  {selectedScopes.length}/{selectableScopes.length} selected
                </span>
              </div>
            </>
          ) : (
            <div className="scope-list">
              <div className="empty-state">No selectable permissions found.</div>
            </div>
          )}

          <hr className="divider" />

          {/* Actions */}
          <div className="action-row">
            <button
              type="button"
              className="approve-btn"
              onClick={handleApprove}
            >
              Approve
            </button>
            <button
              type="button"
              className="deny-btn"
              onClick={handleDeny}
            >
              Deny
            </button>
          </div>

        </div>
      </main>

      {/* Footer */}
      <footer className="consent-footer">WSO2 Healthcare | © {new Date().getFullYear()}</footer>
    </div>
  );
}
