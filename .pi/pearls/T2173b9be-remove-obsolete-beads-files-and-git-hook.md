{
  "id": "2173b9be",
  "title": "Remove obsolete Beads files and Git hooks",
  "tags": [
    "maintenance"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:45:16.429Z",
  "priority": 2,
  "closed_at": "2026-11-06T04:46:09.694Z",
  "slug": "remove-obsolete-beads-files-and-git-hook"
}

# Remove obsolete Beads files and Git hooks

## Description

Remove the legacy .beads directory and all local hooks that invoke bd, including hook backups. Keep migrated Pearls records and update documentation to refer to Git history for the original migration source.

Removed .beads and seven local Beads hooks/backups: pre-commit, pre-commit.backup, pre-push, post-merge, post-merge.backup, post-checkout, and prepare-commit-msg. Updated workflow and migration docs to reference the source in Git history. Verified no Beads references remain in .git/hooks and all 171 migrated records remain intact. git diff --check passed; no application code changed.
