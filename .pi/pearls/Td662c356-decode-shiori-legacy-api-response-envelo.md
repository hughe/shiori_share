{
  "id": "d662c356",
  "title": "Decode Shiori legacy API response envelopes",
  "tags": [
    "bug"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:35:42.020Z",
  "priority": 1,
  "closed_at": "2026-11-06T04:44:07.407Z",
  "slug": "decode-shiori-legacy-api-response-envelo"
}

# Decode Shiori legacy API response envelopes

## Description

The v1.8.0 test server accepts a Bearer JWT but GET /api/tags returns a dictionary, while ShioriClient expects a bare array. Support the upstream ok/message response envelope for tags and bookmark creation while retaining v1.7.x payload support. Make the CLI probe distinguish HTTP authentication rejection from response decoding failures. Add regression tests and build the CLI and app.

Confirmed upstream v1.8.0 MessageResponseMiddleware wraps JSON in ok/message. Legacy handlers still emit the same underlying tags array and bookmark object. Added a decoder for bare and enveloped legacy payloads, with failed/malformed envelope rejection; updated probe to distinguish 401/403 rejection, HTTP-success decoding failure, and other request failures.

Validation passed: make test (iPhone 17 Simulator), make cli, and make build-macos. The rebuilt CLI also passed six localhost fixture checks: bare and wrapped tag success, malformed HTTP-success payload diagnostics, 401 rejection, 502 failure diagnostics, and wrapped bookmark creation. Live-server probe remains to be rerun with the user's credentials.

Upstream source: https://github.com/go-shiori/shiori/blob/v1.8.0/internal/http/middleware/message_response.go

Live probe exposed a second schema difference: v1.8.0 TagDTO uses bookmark_count, while v1.7.4 uses nBookmarks with omitempty. Updated parsing for both keys and omitted zero counts. Corrected v1.8.0 regression fixtures to match upstream TagDTO, including deleted. Previous wrapped fixtures covered the envelope but used the old count field.

Final validation passed after tag-schema fix: make test, make cli, make build-macos, and all six localhost CLI checks. User reran the rebuilt CLI against https://shiori-emberson-test.fly.dev: Bearer accepted and 394 tags decoded successfully. Legacy session-id requests still return 502 on that server. Bookmark creation and device share-sheet checks remain in TODO.md.
