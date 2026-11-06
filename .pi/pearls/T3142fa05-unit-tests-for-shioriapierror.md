{
  "id": "3142fa05",
  "title": "Unit tests for ShioriAPIError",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:38.560Z",
  "priority": 3,
  "slug": "unit-tests-for-shioriapierror"
}

Legacy Beads ID: `ss-gpu`

Test ShioriAPIError enum:
- errorDescription: verify each case returns expected user-facing message
- isRetryable: connectionFailed, serverError, unauthorized → true; others → false

## Closure

Closed

## Relationships

- blocks: T94682abf (legacy `ss-5y7`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-gpu",
  "title": "Unit tests for ShioriAPIError",
  "description": "Test ShioriAPIError enum:\n- errorDescription: verify each case returns expected user-facing message\n- isRetryable: connectionFailed, serverError, unauthorized → true; others → false",
  "status": "closed",
  "priority": 3,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "estimated_minutes": 15,
  "created_at": "2026-01-22T18:17:23.981325Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T19:02:06.001819Z",
  "closed_at": "2026-01-22T19:02:06.001819Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-gpu",
      "depends_on_id": "ss-5y7",
      "type": "blocks",
      "created_at": "2026-01-22T18:17:23.982197Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
