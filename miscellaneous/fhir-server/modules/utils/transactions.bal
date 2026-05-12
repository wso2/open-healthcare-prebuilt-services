// WORK.md §5.1 / Phase 3: with the handlers wrapped in a real Ballerina
// `transaction { ... check commit; }` block, atomicity and rollback are
// delegated to the JDBC layer. The application-level backup/restore machinery
// that this module previously provided is gone.
//
// What remains is a small bookkeeping record carried through commons.bal's
// reference helpers (`saveReferences`, `deleteReferencesBySource`) — they
// still flip flags on it for log/debug parity with the prior implementation.
// The fields and the factory are kept so those helper signatures don't churn.

public type TransactionContext record {|
    string? mainResourceId = ();
    boolean referencesSaved = false;
    int[] deletedReferenceIds = [];
    boolean committed = false;
|};

public isolated function newTransactionContext() returns TransactionContext {
    return {
        mainResourceId: (),
        referencesSaved: false,
        deletedReferenceIds: [],
        committed: false
    };
}
