{
  "id": "1bf51785",
  "title": "Reuse ShioriAPI.login() in SettingsView.testConnection()",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:31.985Z",
  "priority": 3,
  "slug": "reuse-shioriapi-login-in-settingsview-te"
}

Legacy Beads ID: `ss-ct9`

SettingsView.testConnection() reimplements login request construction and status handling. Instead, add a login(username:password:serverURL:) overload to ShioriAPI that doesn't depend on stored settings, and call it from SettingsView. This eliminates drift risk and improves testability.

## Closure

Closed

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-ct9",
  "title": "Reuse ShioriAPI.login() in SettingsView.testConnection()",
  "description": "SettingsView.testConnection() reimplements login request construction and status handling. Instead, add a login(username:password:serverURL:) overload to ShioriAPI that doesn't depend on stored settings, and call it from SettingsView. This eliminates drift risk and improves testability.",
  "status": "closed",
  "priority": 3,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "estimated_minutes": 30,
  "created_at": "2026-01-22T18:13:08.618272Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T20:06:55.924594Z",
  "closed_at": "2026-01-22T20:06:55.924594Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0
}
```
