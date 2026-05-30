package store

import (
	"context"
	"fmt"
	"log/slog"
	"net/url"
	"sort"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// ─── Bundle request / response types ──────────────────────────────────────────

// BundleEntryRequest is one parsed entry of a transaction or batch Bundle.
type BundleEntryRequest struct {
	FullURL     string         // entry.fullUrl (e.g. "urn:uuid:…" or an absolute URL)
	Resource    map[string]any // entry.resource (nil for GET/DELETE)
	Method      string         // entry.request.method — GET, POST, PUT, PATCH, DELETE
	URL         string         // entry.request.url — "Patient", "Patient/123", "Patient?name=x"
	IfMatch     string         // entry.request.ifMatch — ETag, e.g. W/"2"
	IfNoneExist string         // entry.request.ifNoneExist — conditional-create query
}

// BundleEntryResult is the outcome of processing one entry. It maps to a
// transaction-response / batch-response Bundle entry.
type BundleEntryResult struct {
	Status   string         // HTTP status line, e.g. "201 Created"
	Location string         // entry.response.location (relative, e.g. "Patient/123/_history/1")
	ETag     string         // entry.response.etag, e.g. W/"1"
	Resource map[string]any // entry.resource for the response (POST/PUT/GET payloads)
	Outcome  map[string]any // OperationOutcome — set for batch entries that failed

	// Method/ResourceType/ID describe the interaction that produced this result.
	// They let the handler run post-commit maintenance (e.g. SearchParameter
	// registry sync/cleanup) uniformly, including for DELETE which has no Resource.
	Method       string
	ResourceType string
	ID           string
}

// BundleError is returned by ExecuteBundle when a transaction (atomic) Bundle
// fails. It carries the HTTP status the handler should surface and a diagnostic
// message; the whole transaction has already been rolled back.
type BundleError struct {
	HTTPStatus  int
	Code        string // FHIR issue code, e.g. "processing", "not-found"
	EntryIndex  int    // 0-based index of the offending entry, or -1
	Diagnostics string
}

func (e *BundleError) Error() string {
	if e.EntryIndex >= 0 {
		return fmt.Sprintf("bundle entry %d: %s", e.EntryIndex, e.Diagnostics)
	}
	return e.Diagnostics
}

// bundleOp is the planned, reference-resolved form of a BundleEntryRequest,
// ready for ordered execution.
type bundleOp struct {
	origIndex    int
	method       string
	resourceType string
	id           string // resolved target id (PUT/PATCH/DELETE/GET-read)
	versionID    string // for GET vread (_history/{vid})
	body         map[string]any
	ifMatch      int        // parsed If-Match version, or -1 for none
	query        url.Values // GET search / conditional delete filter
	isSearch     bool       // GET against a type (search) vs GET of an instance (read)
	allowCreate  bool       // PUT may create when the target is missing (conditional update, 0 matches)

	// conditional-create / -update that matched an existing resource: no write
	// is performed and the entry resolves to the matched resource.
	skip        bool
	skipStatus  string
	skipResType string
	skipID      string
}

// ─── Entry point ──────────────────────────────────────────────────────────────

// ExecuteBundle processes a transaction or batch Bundle.
//
//   - "transaction": all entries are applied atomically in a single DB
//     transaction. urn:uuid references between entries are resolved, entries are
//     processed in FHIR verb order (DELETE, POST, PUT/PATCH, GET), and any error
//     rolls the whole Bundle back and returns a *BundleError.
//   - "batch": each entry is applied independently in its own transaction; a
//     failing entry yields an OperationOutcome in its response and does not
//     affect the others. ExecuteBundle itself returns a nil error.
//
// baseURL is used to recognise references written as absolute URLs.
func (s *Store) ExecuteBundle(ctx context.Context, bundleType, baseURL string, entries []BundleEntryRequest) ([]BundleEntryResult, error) {
	switch bundleType {
	case "transaction":
		return s.executeTransaction(ctx, baseURL, entries)
	case "batch":
		return s.executeBatch(ctx, baseURL, entries), nil
	default:
		return nil, &BundleError{
			HTTPStatus:  400,
			Code:        "value",
			EntryIndex:  -1,
			Diagnostics: fmt.Sprintf("Bundle.type must be 'transaction' or 'batch', got %q", bundleType),
		}
	}
}

// ─── Transaction (atomic) ──────────────────────────────────────────────────────

func (s *Store) executeTransaction(ctx context.Context, baseURL string, entries []BundleEntryRequest) ([]BundleEntryResult, error) {
	// Plan: assign ids, resolve conditionals, build the reference map.
	ops, refMap, err := s.planOps(ctx, baseURL, entries)
	if err != nil {
		return nil, err
	}

	// Rewrite urn:uuid / absolute-URL references to "Type/id" form across every
	// resource body so inter-entry references point at the assigned ids.
	for i := range ops {
		if ops[i].body != nil {
			rewriteReferences(ops[i].body, refMap)
		}
	}

	// Process in FHIR verb order, preserving original order within each verb.
	order := make([]int, len(ops))
	for i := range order {
		order[i] = i
	}
	sort.SliceStable(order, func(a, b int) bool {
		return methodOrder(ops[order[a]].method) < methodOrder(ops[order[b]].method)
	})

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, &BundleError{HTTPStatus: 500, Code: "exception", EntryIndex: -1, Diagnostics: err.Error()}
	}
	defer tx.Rollback(ctx)

	results := make([]BundleEntryResult, len(ops))
	for _, idx := range order {
		op := ops[idx]
		res, berr := s.execOpInTx(ctx, tx, op)
		if berr != nil {
			berr.EntryIndex = op.origIndex
			return nil, berr // defer rolls the whole transaction back
		}
		results[op.origIndex] = res
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, &BundleError{HTTPStatus: 500, Code: "exception", EntryIndex: -1, Diagnostics: err.Error()}
	}

	slog.Info("processed transaction bundle", "entries", len(entries))
	return results, nil
}

// execOpInTx runs a single planned op against an open transaction, stamping the
// result with the interaction's method/type/id so the caller can run post-commit
// maintenance (e.g. SearchParameter registry sync) uniformly. A returned
// *BundleError aborts (and rolls back) the whole transaction.
func (s *Store) execOpInTx(ctx context.Context, tx pgx.Tx, op bundleOp) (BundleEntryResult, *BundleError) {
	res, berr := s.runOpInTx(ctx, tx, op)
	if berr != nil {
		return res, berr
	}
	res.Method = op.method
	if op.skip && op.skipResType != "" {
		res.ResourceType = op.skipResType
		res.ID = op.skipID
	} else {
		res.ResourceType = op.resourceType
		if res.ID == "" {
			res.ID = op.id
		}
	}
	return res, nil
}

// runOpInTx executes a single planned op against the open transaction.
func (s *Store) runOpInTx(ctx context.Context, tx pgx.Tx, op bundleOp) (BundleEntryResult, *BundleError) {
	if op.skip {
		return BundleEntryResult{
			Status:   op.skipStatus,
			Location: op.skipResType + "/" + op.skipID,
		}, nil
	}

	switch op.method {
	case "POST":
		res, err := s.createInTx(ctx, tx, op.resourceType, op.body)
		if err != nil {
			return BundleEntryResult{}, storeErrToBundleErr(err)
		}
		id, _ := res["id"].(string)
		return BundleEntryResult{
			Status:   "201 Created",
			Location: fmt.Sprintf("%s/%s/_history/%s", op.resourceType, id, metaVersionID(res)),
			ETag:     etag(res),
			Resource: res,
		}, nil

	case "PUT":
		res, err := s.updateInTx(ctx, tx, op.resourceType, op.id, op.body, op.ifMatch)
		if err != nil {
			// A conditional update that matched zero resources creates the target;
			// a plain PUT to a missing id is a 404 (the server does not do
			// update-as-create), which in a transaction rolls everything back.
			if _, ok := err.(NotFoundError); ok && op.allowCreate {
				op.body["id"] = op.id
				cres, cerr := s.createInTx(ctx, tx, op.resourceType, op.body)
				if cerr != nil {
					return BundleEntryResult{}, storeErrToBundleErr(cerr)
				}
				cid, _ := cres["id"].(string)
				return BundleEntryResult{
					Status:   "201 Created",
					Location: fmt.Sprintf("%s/%s/_history/%s", op.resourceType, cid, metaVersionID(cres)),
					ETag:     etag(cres),
					Resource: cres,
				}, nil
			}
			return BundleEntryResult{}, storeErrToBundleErr(err)
		}
		id, _ := res["id"].(string)
		return BundleEntryResult{
			Status:   "200 OK",
			Location: fmt.Sprintf("%s/%s/_history/%s", op.resourceType, id, metaVersionID(res)),
			ETag:     etag(res),
			Resource: res,
		}, nil

	case "PATCH":
		res, _, err := s.patchInTx(ctx, tx, op.resourceType, op.id, op.body)
		if err != nil {
			return BundleEntryResult{}, storeErrToBundleErr(err)
		}
		id, _ := res["id"].(string)
		return BundleEntryResult{
			Status:   "200 OK",
			Location: fmt.Sprintf("%s/%s/_history/%s", op.resourceType, id, metaVersionID(res)),
			ETag:     etag(res),
			Resource: res,
		}, nil

	case "DELETE":
		if err := s.deleteInTx(ctx, tx, op.resourceType, op.id); err != nil {
			if _, ok := err.(NotFoundError); ok {
				// Deleting something that does not exist is a no-op success.
				return BundleEntryResult{Status: "204 No Content"}, nil
			}
			return BundleEntryResult{}, storeErrToBundleErr(err)
		}
		return BundleEntryResult{Status: "204 No Content"}, nil

	case "GET":
		return s.execGetInTx(ctx, tx, op)

	default:
		return BundleEntryResult{}, &BundleError{
			HTTPStatus: 405, Code: "not-supported",
			Diagnostics: fmt.Sprintf("unsupported Bundle request method %q", op.method),
		}
	}
}

func (s *Store) execGetInTx(ctx context.Context, tx pgx.Tx, op bundleOp) (BundleEntryResult, *BundleError) {
	// Instance read (optionally a specific version) is served from the open
	// transaction so it reflects earlier entries in the same Bundle.
	if !op.isSearch {
		if op.versionID != "" {
			vid, _ := strconv.Atoi(op.versionID)
			res, err := s.GetVersion(ctx, op.resourceType, op.id, vid)
			if err != nil {
				return BundleEntryResult{}, storeErrToBundleErr(err)
			}
			return BundleEntryResult{Status: "200 OK", Resource: res, ETag: etag(res)}, nil
		}
		res, err := s.readInTx(ctx, tx, op.resourceType, op.id)
		if err != nil {
			return BundleEntryResult{}, storeErrToBundleErr(err)
		}
		return BundleEntryResult{Status: "200 OK", Resource: res, ETag: etag(res)}, nil
	}

	// Search is served from the committed snapshot (the pool), so it does not
	// observe not-yet-committed writes from earlier entries in this Bundle.
	result, err := s.Search(ctx, SearchParams{ResourceType: op.resourceType, Params: valuesToMap(op.query)})
	if err != nil {
		return BundleEntryResult{}, &BundleError{HTTPStatus: 500, Code: "exception", Diagnostics: err.Error()}
	}
	return BundleEntryResult{Status: "200 OK", Resource: searchsetBundle(result)}, nil
}

// ─── Batch (independent entries) ───────────────────────────────────────────────

func (s *Store) executeBatch(ctx context.Context, baseURL string, entries []BundleEntryRequest) []BundleEntryResult {
	results := make([]BundleEntryResult, len(entries))
	for i, e := range entries {
		ops, _, err := s.planOps(ctx, baseURL, []BundleEntryRequest{e})
		if err != nil {
			results[i] = batchFailure(err)
			continue
		}
		op := ops[0]
		op.origIndex = 0

		tx, txerr := s.pool.Begin(ctx)
		if txerr != nil {
			results[i] = batchFailure(&BundleError{HTTPStatus: 500, Code: "exception", Diagnostics: txerr.Error()})
			continue
		}
		res, berr := s.execOpInTx(ctx, tx, op)
		if berr != nil {
			tx.Rollback(ctx)
			results[i] = batchFailure(berr)
			continue
		}
		if cerr := tx.Commit(ctx); cerr != nil {
			results[i] = batchFailure(&BundleError{HTTPStatus: 500, Code: "exception", Diagnostics: cerr.Error()})
			continue
		}
		results[i] = res
	}
	slog.Info("processed batch bundle", "entries", len(entries))
	return results
}

func batchFailure(err error) BundleEntryResult {
	be, ok := err.(*BundleError)
	if !ok {
		be = &BundleError{HTTPStatus: 500, Code: "exception", Diagnostics: err.Error()}
	}
	return BundleEntryResult{
		Status:  fmt.Sprintf("%d %s", be.HTTPStatus, httpReason(be.HTTPStatus)),
		Outcome: operationOutcomeMap("error", be.Code, be.Diagnostics),
	}
}

// ─── Planning: id assignment, conditional resolution, reference map ────────────

func (s *Store) planOps(ctx context.Context, baseURL string, entries []BundleEntryRequest) ([]bundleOp, map[string]string, error) {
	ops := make([]bundleOp, len(entries))
	refMap := map[string]string{}

	for i, e := range entries {
		method := strings.ToUpper(strings.TrimSpace(e.Method))
		if method == "" {
			return nil, nil, &BundleError{HTTPStatus: 400, Code: "required", EntryIndex: i, Diagnostics: "entry.request.method is required"}
		}
		rt, id, vid, query, perr := parseEntryURL(baseURL, e.URL)
		if perr != "" {
			return nil, nil, &BundleError{HTTPStatus: 400, Code: "value", EntryIndex: i, Diagnostics: perr}
		}

		op := bundleOp{origIndex: i, method: method, resourceType: rt, id: id, versionID: vid, body: e.Resource, ifMatch: -1}

		if e.IfMatch != "" {
			if v, ok := parseETagVersion(e.IfMatch); ok {
				op.ifMatch = v
			} else {
				return nil, nil, &BundleError{HTTPStatus: 400, Code: "value", EntryIndex: i, Diagnostics: "invalid If-Match in entry.request.ifMatch"}
			}
		}

		switch method {
		case "POST":
			if rt == "" {
				return nil, nil, &BundleError{HTTPStatus: 400, Code: "value", EntryIndex: i, Diagnostics: "POST entry.request.url must be a resource type"}
			}
			// Conditional create (If-None-Exist): reuse an existing match if present.
			if e.IfNoneExist != "" {
				existingID, count, serr := s.conditionalMatch(ctx, rt, e.IfNoneExist)
				if serr != nil {
					return nil, nil, &BundleError{HTTPStatus: 500, Code: "exception", EntryIndex: i, Diagnostics: serr.Error()}
				}
				if count > 1 {
					return nil, nil, &BundleError{HTTPStatus: 412, Code: "conflict", EntryIndex: i, Diagnostics: fmt.Sprintf("If-None-Exist matched %d resources", count)}
				}
				if count == 1 {
					op.skip = true
					op.skipStatus = "200 OK"
					op.skipResType = rt
					op.skipID = existingID
					if e.FullURL != "" {
						refMap[e.FullURL] = rt + "/" + existingID
					}
					ops[i] = op
					continue
				}
			}
			// Assign an id up front so other entries can reference this one.
			newID := assignedID(e.Resource)
			op.id = newID
			if op.body == nil {
				op.body = map[string]any{}
			}
			op.body["id"] = newID
			op.body["resourceType"] = rt
			if e.FullURL != "" {
				refMap[e.FullURL] = rt + "/" + newID
			}

		case "PUT":
			if rt == "" {
				return nil, nil, &BundleError{HTTPStatus: 400, Code: "value", EntryIndex: i, Diagnostics: "PUT entry.request.url must include a resource type"}
			}
			// Conditional update: url carries a query and no id.
			if id == "" && len(query) > 0 {
				existingID, count, serr := s.conditionalMatch(ctx, rt, query.Encode())
				if serr != nil {
					return nil, nil, &BundleError{HTTPStatus: 500, Code: "exception", EntryIndex: i, Diagnostics: serr.Error()}
				}
				if count > 1 {
					return nil, nil, &BundleError{HTTPStatus: 412, Code: "conflict", EntryIndex: i, Diagnostics: fmt.Sprintf("conditional update matched %d resources", count)}
				}
				if count == 1 {
					op.id = existingID
				} else {
					op.id = assignedID(e.Resource) // create with a fresh (or body-supplied) id
					op.allowCreate = true
				}
			}
			if op.id == "" {
				return nil, nil, &BundleError{HTTPStatus: 400, Code: "value", EntryIndex: i, Diagnostics: "PUT entry.request.url must include an id or a conditional query"}
			}
			if e.FullURL != "" {
				refMap[e.FullURL] = rt + "/" + op.id
			}

		case "PATCH", "DELETE":
			// Conditional delete: url carries a query and no id.
			if id == "" && len(query) > 0 {
				existingID, count, serr := s.conditionalMatch(ctx, rt, query.Encode())
				if serr != nil {
					return nil, nil, &BundleError{HTTPStatus: 500, Code: "exception", EntryIndex: i, Diagnostics: serr.Error()}
				}
				if count == 0 {
					op.skip = true
					op.skipStatus = "204 No Content"
					ops[i] = op
					continue
				}
				if count > 1 {
					return nil, nil, &BundleError{HTTPStatus: 412, Code: "conflict", EntryIndex: i, Diagnostics: fmt.Sprintf("conditional %s matched %d resources", method, count)}
				}
				op.id = existingID
			}
			if op.id == "" {
				return nil, nil, &BundleError{HTTPStatus: 400, Code: "value", EntryIndex: i, Diagnostics: method + " entry.request.url must include an id or a conditional query"}
			}

		case "GET":
			if rt == "" {
				return nil, nil, &BundleError{HTTPStatus: 400, Code: "value", EntryIndex: i, Diagnostics: "GET entry.request.url must include a resource type"}
			}
			op.isSearch = id == ""
			op.query = query
		}

		ops[i] = op
	}

	return ops, refMap, nil
}

// conditionalMatch runs a search and returns the single matched id (if count==1),
// the total match count, and any error.
func (s *Store) conditionalMatch(ctx context.Context, resourceType, rawQuery string) (id string, count int, err error) {
	q, perr := url.ParseQuery(rawQuery)
	if perr != nil {
		return "", 0, perr
	}
	result, serr := s.Search(ctx, SearchParams{ResourceType: resourceType, Params: valuesToMap(q), PageSize: 2})
	if serr != nil {
		return "", 0, serr
	}
	if result.Total == 1 && len(result.Entries) == 1 {
		id, _ = result.Entries[0]["id"].(string)
	}
	return id, result.Total, nil
}

// ─── URL / reference helpers ───────────────────────────────────────────────────

// parseEntryURL splits a Bundle entry.request.url (relative to the FHIR base,
// or absolute under baseURL) into its parts. On a malformed URL it returns a
// non-empty error string.
func parseEntryURL(baseURL, raw string) (resourceType, id, versionID string, query url.Values, errMsg string) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "", "", "", nil, "entry.request.url is required"
	}
	// Strip an absolute base if present.
	if baseURL != "" && strings.HasPrefix(raw, baseURL) {
		raw = strings.TrimPrefix(raw, baseURL)
	} else if i := strings.Index(raw, "://"); i >= 0 {
		if slash := strings.IndexByte(raw[i+3:], '/'); slash >= 0 {
			raw = raw[i+3+slash:]
		}
	}
	raw = strings.TrimPrefix(raw, "/")

	path := raw
	if q := strings.IndexByte(raw, '?'); q >= 0 {
		path = raw[:q]
		parsed, err := url.ParseQuery(raw[q+1:])
		if err != nil {
			return "", "", "", nil, "invalid query string in entry.request.url"
		}
		query = parsed
	}

	parts := strings.Split(strings.Trim(path, "/"), "/")
	switch {
	case len(parts) >= 4 && parts[2] == "_history":
		// Type/id/_history/vid
		return parts[0], parts[1], parts[3], query, ""
	case len(parts) == 2:
		return parts[0], parts[1], "", query, ""
	case len(parts) == 1:
		return parts[0], "", "", query, ""
	default:
		return "", "", "", nil, fmt.Sprintf("unsupported entry.request.url %q", raw)
	}
}

// assignedID returns the resource's own id if present, otherwise a new uuid.
func assignedID(body map[string]any) string {
	if body != nil {
		if id, ok := body["id"].(string); ok && id != "" {
			return id
		}
	}
	return uuid.NewString()
}

// rewriteReferences walks a resource and rewrites any {"reference": "<key>"}
// whose value matches a key in refMap (a urn:uuid or absolute URL) to the
// resolved "Type/id" form. It recurses through nested objects and arrays.
func rewriteReferences(node any, refMap map[string]string) {
	switch v := node.(type) {
	case map[string]any:
		if ref, ok := v["reference"].(string); ok {
			if resolved, found := refMap[ref]; found {
				v["reference"] = resolved
			}
		}
		for _, child := range v {
			rewriteReferences(child, refMap)
		}
	case []any:
		for _, child := range v {
			rewriteReferences(child, refMap)
		}
	}
}

// methodOrder gives the FHIR transaction processing order for a verb.
func methodOrder(method string) int {
	switch method {
	case "DELETE":
		return 0
	case "POST":
		return 1
	case "PUT":
		return 2
	case "PATCH":
		return 3
	default: // GET, HEAD
		return 4
	}
}

// ─── Small shared helpers ──────────────────────────────────────────────────────

func valuesToMap(v url.Values) map[string][]string {
	m := make(map[string][]string, len(v))
	for k, vs := range v {
		m[k] = vs
	}
	return m
}

func etag(res map[string]any) string {
	if v := metaVersionID(res); v != "" {
		return fmt.Sprintf(`W/"%s"`, v)
	}
	return ""
}

// parseETagVersion parses an ETag like W/"3" into its integer version.
func parseETagVersion(header string) (int, bool) {
	s := strings.TrimSpace(header)
	s = strings.TrimPrefix(s, "W/")
	s = strings.Trim(s, `"`)
	v, err := strconv.Atoi(s)
	return v, err == nil
}

func operationOutcomeMap(severity, code, diagnostics string) map[string]any {
	return map[string]any{
		"resourceType": "OperationOutcome",
		"issue": []any{map[string]any{
			"severity":    severity,
			"code":        code,
			"diagnostics": diagnostics,
		}},
	}
}

// searchsetBundle wraps search results in a minimal searchset Bundle for use as
// a GET response inside a transaction/batch response.
func searchsetBundle(result SearchResult) map[string]any {
	entries := make([]any, 0, len(result.Entries))
	for _, res := range result.Entries {
		entries = append(entries, map[string]any{
			"resource": res,
			"search":   map[string]any{"mode": "match"},
		})
	}
	return map[string]any{
		"resourceType": "Bundle",
		"type":         "searchset",
		"total":        result.Total,
		"entry":        entries,
	}
}

// storeErrToBundleErr maps a store CRUD error to the HTTP status a Bundle entry
// (or a failed transaction) should report.
func storeErrToBundleErr(err error) *BundleError {
	switch e := err.(type) {
	case NotFoundError:
		return &BundleError{HTTPStatus: 404, Code: "not-found", Diagnostics: e.Error()}
	case GoneError:
		return &BundleError{HTTPStatus: 410, Code: "deleted", Diagnostics: e.Error()}
	case ConflictError:
		return &BundleError{HTTPStatus: 412, Code: "conflict", Diagnostics: e.Error()}
	default:
		return &BundleError{HTTPStatus: 500, Code: "exception", Diagnostics: err.Error()}
	}
}

func httpReason(status int) string {
	switch status {
	case 200:
		return "OK"
	case 201:
		return "Created"
	case 204:
		return "No Content"
	case 400:
		return "Bad Request"
	case 404:
		return "Not Found"
	case 405:
		return "Method Not Allowed"
	case 410:
		return "Gone"
	case 412:
		return "Precondition Failed"
	case 422:
		return "Unprocessable Entity"
	default:
		return "Internal Server Error"
	}
}
