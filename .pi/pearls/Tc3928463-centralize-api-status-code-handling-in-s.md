{
  "id": "c3928463",
  "title": "Centralize API status code handling in ShioriAPI",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:55.880Z",
  "priority": 3,
  "slug": "centralize-api-status-code-handling-in-s"
}

Legacy Beads ID: `ss-xmb`

login(), addBookmark(), and fetchTags() repeat the same status code handling flow. Introduce a generic send<T: Decodable>() helper that validates HTTPURLResponse, maps 401 to .unauthorized, 404 to .notFound, 5xx to .serverError, and decodes consistently.

## Closure

Completed - added mapStatusCode() helper

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-xmb",
  "title": "Centralize API status code handling in ShioriAPI",
  "description": "login(), addBookmark(), and fetchTags() repeat the same status code handling flow. Introduce a generic send<T: Decodable>() helper that validates HTTPURLResponse, maps 401 to .unauthorized, 404 to .notFound, 5xx to .serverError, and decodes consistently.",
  "status": "closed",
  "priority": 3,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "estimated_minutes": 45,
  "created_at": "2026-01-22T18:13:08.488659Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T18:36:07.492045Z",
  "closed_at": "2026-01-22T18:36:07.492045Z",
  "close_reason": "Completed - added mapStatusCode() helper",
  "source_repo": ".",
  "compaction_level": 0
}
```
