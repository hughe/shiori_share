{
  "id": "a9fc3c5d",
  "title": "Unit tests for mapNetworkError",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:36.377Z",
  "priority": 3,
  "slug": "unit-tests-for-mapnetworkerror"
}

Legacy Beads ID: `ss-d1w`

Extract mapNetworkError from ShioriAPI as a testable function and add tests:
- Certificate errors: serverCertificateUntrusted, secureConnectionFailed, etc. → .certificateError
- Connection errors: cannotFindHost, timedOut, notConnectedToInternet, etc. → .connectionFailed
- Other URLError codes → .unknownError
- Non-URLError errors → .unknownError

## Closure

Closed

## Relationships

- blocks: T94682abf (legacy `ss-5y7`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-d1w",
  "title": "Unit tests for mapNetworkError",
  "description": "Extract mapNetworkError from ShioriAPI as a testable function and add tests:\n- Certificate errors: serverCertificateUntrusted, secureConnectionFailed, etc. → .certificateError\n- Connection errors: cannotFindHost, timedOut, notConnectedToInternet, etc. → .connectionFailed\n- Other URLError codes → .unknownError\n- Non-URLError errors → .unknownError",
  "status": "closed",
  "priority": 3,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "estimated_minutes": 20,
  "created_at": "2026-01-22T18:17:01.230543Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T19:14:01.504567Z",
  "closed_at": "2026-01-22T19:14:01.504567Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-d1w",
      "depends_on_id": "ss-5y7",
      "type": "blocks",
      "created_at": "2026-01-22T18:17:01.231405Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
