{
  "id": "822b53a5",
  "title": "Add 'Clear Password' option in Settings.bundle",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:01.679Z",
  "priority": 2,
  "parent": "aa8ad3b5",
  "slug": "add-clear-password-option-in-settings-bu"
}

Legacy Beads ID: `ss-9dj.6`

Add a way to clear stored password from Settings.bundle.

## Options
1. PSButtonSpecifier that triggers password clear (requires app launch)
2. PSToggleSwitchSpecifier 'Clear Password on Next Launch'
3. Document: delete and reinstall app to clear keychain

## Recommendation
Use toggle 'Reset Password on Next Use' - when enabled, clear keychain password on next share extension launch and prompt for new password.

## Closure

Closed

## Relationships

- parent-child: Taa8ad3b5 (legacy `ss-9dj`)
- blocks: Tdc6b3fe6 (legacy `ss-9dj.1`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj.6",
  "title": "Add 'Clear Password' option in Settings.bundle",
  "description": "Add a way to clear stored password from Settings.bundle.\n\n## Options\n1. PSButtonSpecifier that triggers password clear (requires app launch)\n2. PSToggleSwitchSpecifier 'Clear Password on Next Launch'\n3. Document: delete and reinstall app to clear keychain\n\n## Recommendation\nUse toggle 'Reset Password on Next Use' - when enabled, clear keychain password on next share extension launch and prompt for new password.",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:39:23.337972Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:47:23.993751Z",
  "closed_at": "2026-01-23T05:47:23.993751Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-9dj.6",
      "depends_on_id": "ss-9dj",
      "type": "parent-child",
      "created_at": "2026-01-23T05:39:23.338628Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    },
    {
      "issue_id": "ss-9dj.6",
      "depends_on_id": "ss-9dj.1",
      "type": "blocks",
      "created_at": "2026-01-23T05:39:33.104770Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
