# TODO: Switch to `Authorization: Bearer` and support Shiori v1.8.0

Goal: make Shiori Share authenticate with `Authorization: Bearer <token>` so it
works with both Shiori v1.7.4 (current prod) and v1.8.0, ship it, and only then
upgrade the server.

Companion plan (server side, test environment, prod rollout): `../shiori/TODO.md`.

## Background

- Login (`POST /api/v1/auth/login`) returns `message.token` (JWT) and, on
  v1.7.x, `message.session`.
- The app currently sends `X-Session-Id: <session>` to the legacy
  `/api/bookmarks` and `/api/tags` endpoints.
- v1.7.4's legacy API checks `Authorization` first, then `X-Session-Id`.
- v1.8.0's legacy API dropped `X-Session-Id`; it only accepts `Authorization`
  (or a `token` cookie). The app's `session ?? token` fallback then sends the
  JWT in a header the server ignores, which is the "v1.8.0 bug" (issue #1176
  was closed as a client auth problem).
- So Bearer works on both versions, and the app can ship before the server
  upgrade.

## Done

- [x] Split HTTP code out of `ShioriAPI` into stateless `Shared/ShioriClient.swift`
      (models, `ShioriAPIError`, `ShioriAuthStyle`, `ShioriCredential`, client).
      `ShioriAPI` keeps its interface and wraps the client.
      Behaviour unchanged: `ShioriAPI.authStyle` is still `.sessionID`.
      (Pre-split copy of `ShioriAPI.swift`, including the uncommitted v1.8.0
      debugging edits, saved at `tmp/ShioriAPI.swift.before-client-split`.)
- [x] Added `ShioriClient.swift` to the app and extension targets in the Xcode project
- [x] `Tools/shiori-cli`: command-line test program built from the shared
      client (`make cli`); commands `login`, `tags`, `add`, `probe`
- [x] Docs: CLAUDE.md updated for ShioriClient / shiori-cli

## Phase 1: Verify the refactor (no behaviour change)

- [x] `make build-sim`, `make build-macos`, `make test`: all green
      (verified after the Bearer switch; 133 tests passed)
- [x] `make cli` builds `build/shiori-cli`
- [ ] Against prod (read-only): `build/shiori-cli --server https://shiori.emberson.net --user <me> probe`
      Expect both `session-id` and `bearer` accepted on v1.7.4
- [ ] Install the refactored build on a device; save a bookmark against prod
      (still X-Session-Id), confirm tags load
- [x] Commit the refactor on its own, separate from the Bearer switch
      (`1674272`)

## Phase 2: Switch the app to Bearer

- [x] `Shared/ShioriAPI.swift`: `static let authStyle: ShioriAuthStyle = .bearer`
      (`ShioriCredential.value(for: .bearer)` returns the token, so login now
      caches the JWT)
- [x] Session cache: invalidate any cached `X-Session-Id` value on upgrade
      (for example, clear the session when the stored auth style differs, or
      rename the cache key), otherwise the first request after upgrade sends an
      old session ID as a Bearer token (it would 401, clear, re-login, and the
      user sees one "Session expired, try again")
- [ ] Consider using the login response's `expires` for cache validity
      (deferred; retain the existing 1-hour cap for this auth switch)
- [ ] Consider moving the cached token from app-group UserDefaults into the Keychain
      (deferred to a separate storage change)
- [x] Remove the hard-coded "Shiori v1.8.0 has a known bug" messages
      (`ShioriAPIError.serverError(502)` text, `.apiNotAvailable`) and the
      comment in `AppConstants.swift`
- [x] Rename `cachedSessionID` / `getValidSession` / `sessionID` to token naming
      (update `SettingsManagerTests`)
- [x] Unit tests: inject a `URLSession` (URLProtocol stub) into `ShioriClient`
      and assert the `Authorization: Bearer` header and login parsing
      (token-only response, v1.8.0 shape)
- [x] Update CLAUDE.md "Session Security" note

- [x] Decode both bare v1.7.x payloads and v1.8.0 `ok`/`message` envelopes
      for tags and bookmark creation; reject failed or malformed envelopes
- [x] Decode v1.8.0 tag `bookmark_count`, legacy `nBookmarks`, and omitted
      zero counts (v1.7.x uses `omitempty`)
- [x] CLI probe distinguishes authentication rejection (401/403) from decoding
      failures after HTTP success and other request failures

## Phase 3: Test against the test environment

Test server: `shiori-emberson-test` (see `../shiori/TODO.md`, Phase 2).

- [ ] Test server on v1.7.4 + Alpine 3.24:
      - `shiori-cli ... probe` -> both styles accepted
      - Bearer app build (pointed at the test server in Settings): save bookmark,
        tags load, tags autocomplete, archive and public toggles
      - Wrong password -> "Invalid username or password"
- [ ] Test server on v1.8.0:
      - [x] `shiori-cli ... probe` -> `bearer` accepted (394 tags),
        `session-id` fails (502); confirmed by user on 2026-11-06
      - [x] Installed macOS and iOS Bearer builds work against the v1.8.0
        test environment (confirmed by user on 2026-11-06)
      - `shiori-cli ... add https://example.com --tags cli-test` -> bookmark created
      - Bearer app build: all checks above, on iPhone and Mac share sheets
      - Restart the test machine (`fly machine restart`) and share again:
        expect transparent re-login if the JWT key changed
- [ ] Point the app back at prod afterwards

## Phase 4: Ship

- [ ] Install the Bearer build on all devices; confirm it works against prod v1.7.4
- [ ] Then the server upgrade can proceed (`../shiori/TODO.md`, Phase 5)
- [ ] After prod is on v1.8.0: run `shiori-cli ... probe` against prod and
      share one bookmark from each device
