# Agent Instructions

## Build Commands

```bash
make build-sim    # Build for iOS Simulator
make build-ios    # Build for iOS device
make build-macos  # Build for macOS (requires signing)
make open         # Open project in Xcode
make clean        # Clean build artifacts
```

## Testing

Unit tests are in `ShioriShareTests/`. Run tests with:

```bash
xcodebuild test -project ShioriShare.xcodeproj -scheme ShioriShare -destination 'platform=iOS Simulator,name=iPhone 17'
```

Current test coverage:
- `StringURLTests` - Tests for String+URL extensions (URL validation, normalization, extraction)
- `URLExtensionTests` - Tests for URL extensions (isHTTP, appendingPathSafely)
- `ParseKeywordsTests` - Tests for ShioriAPI.parseKeywords (tag parsing)

## Project Structure

- `ShioriShare/` - Main app (Instructions + Settings screens)
- `ShareExtension/` - Share extension (bookmark form)
- `Shared/` - Shared code (API client, keychain, settings)

## Issue Tracking

This project uses **Pearls** for issue tracking. Run `pearls quickstart` for the workflow.
Issues live in `.pi/pearls/` and are committed and pushed with other changes.
Do not use `bd`. Legacy Beads records were migrated to Pearls; the original
`.beads/` directory is available in Git history.

## Quick Reference

```bash
pearls list --json              # Find open and assigned work
pearls get T<id>                # View issue details
pearls claim T<id> --session "$PEARLS_SESSION"  # Claim work
pearls append T<id> --body "Progress update"
pearls close T<id>              # Complete work
```

When starting a task, claim it with a stable, unique session ID using
`--session` or the `PEARLS_SESSION` environment variable. Create missing tasks
with `pearls create`. Preserve existing assignments unless explicitly taking
on stale work. Use Pearls commands to modify issue files.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

