{
  "id": "8bc82ef8",
  "title": "Cache URLSession instances instead of creating per-request",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:23.914Z",
  "priority": 3,
  "slug": "cache-urlsession-instances-instead-of-cr"
}

Legacy Beads ID: `ss-bxy`

ShioriAPI.createSession() creates a new URLSession (and delegate) for each request. Cache one shared default session and one trust-self-signed session keyed by host. Rebuild the trusted session only when server URL changes.

## Closure

Don't need caching

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-bxy",
  "title": "Cache URLSession instances instead of creating per-request",
  "description": "ShioriAPI.createSession() creates a new URLSession (and delegate) for each request. Cache one shared default session and one trust-self-signed session keyed by host. Rebuild the trusted session only when server URL changes.",
  "status": "closed",
  "priority": 3,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "estimated_minutes": 30,
  "created_at": "2026-01-22T18:13:08.749661Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T19:54:43.402482Z",
  "closed_at": "2026-01-22T19:54:43.402482Z",
  "close_reason": "Don't need caching",
  "source_repo": ".",
  "compaction_level": 0
}
```
