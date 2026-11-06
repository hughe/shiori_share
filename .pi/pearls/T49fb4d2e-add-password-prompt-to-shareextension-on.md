{
  "id": "49fb4d2e",
  "title": "Add password prompt to ShareExtension on first use",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:00.019Z",
  "priority": 2,
  "parent": "aa8ad3b5",
  "slug": "add-password-prompt-to-shareextension-on"
}

Legacy Beads ID: `ss-9dj.3`

When share extension is used and no password exists in keychain, show a password prompt.

## Implementation
- Check KeychainHelper.shared.password on extension load
- If nil, show modal/alert asking for password
- Store entered password in keychain via KeychainHelper
- Continue with bookmark submission after password entered
- Show clear error if password is wrong (after login attempt fails)

## UX considerations
- Make it clear this is a one-time setup
- Allow password to be updated via 'Forget Password' or re-entry on auth failure

## Closure

Closed

## Relationships

- parent-child: Taa8ad3b5 (legacy `ss-9dj`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj.3",
  "title": "Add password prompt to ShareExtension on first use",
  "description": "When share extension is used and no password exists in keychain, show a password prompt.\n\n## Implementation\n- Check KeychainHelper.shared.password on extension load\n- If nil, show modal/alert asking for password\n- Store entered password in keychain via KeychainHelper\n- Continue with bookmark submission after password entered\n- Show clear error if password is wrong (after login attempt fails)\n\n## UX considerations\n- Make it clear this is a one-time setup\n- Allow password to be updated via 'Forget Password' or re-entry on auth failure",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:39:06.920365Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:48:36.492992Z",
  "closed_at": "2026-01-23T05:48:36.492992Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-9dj.3",
      "depends_on_id": "ss-9dj",
      "type": "parent-child",
      "created_at": "2026-01-23T05:39:06.921004Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
