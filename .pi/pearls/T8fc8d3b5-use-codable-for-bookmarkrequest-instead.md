{
  "id": "8fc8d3b5",
  "title": "Use Codable for BookmarkRequest instead of JSONSerialization",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:31:57.323Z",
  "priority": 3,
  "slug": "use-codable-for-bookmarkrequest-instead"
}

Legacy Beads ID: `ss-8z5`

ShioriAPI.addBookmark() uses manual [String: Any] JSON construction. Codable with encodeIfPresent omits nil fields automatically. Refactor BookmarkRequest to be Encodable and use JSONEncoder, improving type safety.

## Closure

Completed in commits 471290f, 3bb562a, 33d940e

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-8z5",
  "title": "Use Codable for BookmarkRequest instead of JSONSerialization",
  "description": "ShioriAPI.addBookmark() uses manual [String: Any] JSON construction. Codable with encodeIfPresent omits nil fields automatically. Refactor BookmarkRequest to be Encodable and use JSONEncoder, improving type safety.",
  "status": "closed",
  "priority": 3,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "estimated_minutes": 20,
  "created_at": "2026-01-22T18:13:09.007912Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T18:34:02.886738Z",
  "closed_at": "2026-01-22T18:34:02.886738Z",
  "close_reason": "Completed in commits 471290f, 3bb562a, 33d940e",
  "source_repo": ".",
  "compaction_level": 0
}
```
