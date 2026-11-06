# Pearls issue tracking

Run `pearls quickstart` for the workflow. Use Pearls commands to create,
claim, update, and close issues; commit and push the resulting files with Git.

## Beads migration

All 171 records from `.beads/issues.jsonl` were imported via `pearls create`
and `pearls update`: 8 open and 163 closed. The local Beads database was
checked against the export for issue content and status; it contained no
additional comments, labels, or issue notes.

- `beads-id-map.json` maps every original Beads ID to its Pearls ID.
- Titles, statuses, priorities, and issue types (as tags) are preserved.
- Parent-child links use the native Pearls parent field.
- All 136 relationships are listed in issue bodies with both IDs. Blocking
  relationships are documentation, not enforced by Pearls.
- Each body includes the complete original JSON record, preserving original
  creation/update/closure timestamps, ownership, estimates, and closure notes.
  Pearls timestamps reflect import time.
- `.beads/` remains as a historical source; do not use `bd`.

Closed issues may later move into `archive/` through Pearls garbage collection.
Use `pearls list-all --archived --json` to include them. Search old IDs in the
mapping file; `pearls get` accepts the mapped Pearls ID.
