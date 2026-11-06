{
  "id": "3584d547",
  "title": "Avoid blocking keychain dialog after Safari extension updates",
  "tags": [
    "bug"
  ],
  "status": "open",
  "created_at": "2026-11-06T05:05:54.212Z",
  "priority": 2,
  "slug": "avoid-blocking-keychain-dialog-on-first"
}

# Avoid blocking keychain dialog on first Safari share

## Description

On the first run of each new version of the macOS share extension from Safari, an unwanted system Keychain authorization dialog appears over the extension’s Loading screen. It says “Save to Shiori (Safari) wants to use your confidential information stored in ‘net.emberson.shiorishare’ in your keychain” and asks for the login keychain password.

The user cannot enter anything into that system dialog. Pressing Escape dismisses it and allows the extension to proceed to its own “Enter Password” screen. The user can then enter the Shiori password, and it is saved successfully.

Steps to reproduce:
1. Install a new version of the macOS share extension.
2. Run that version from Safari for the first time.
3. Observe the system Keychain authorization dialog; its password field does not accept input.
4. Press Escape.
5. Enter the Shiori password in the extension’s own password screen and continue; the password is saved.

The user reports this only happens on the first run of a new extension version; subsequent runs of the same version are unaffected. The browser is Safari.

Expected: The first-run flow after an extension update reaches the extension’s Shiori password prompt without a blocking, unusable system Keychain dialog. Subsequent use can access the saved password normally.

Reported after installing macOS version 0.4.0. Root cause has not been investigated.

Screenshots supplied by the user:
- tmp/Unwanted permission dialog.png — blocking system Keychain dialog (Image #1).
- tmp/Expected permsisson dialog.png — usable Shiori password prompt after Escape (Image #2; filename spelling preserved).

Screenshots archived with this issue:
- [Unwanted system Keychain dialog](assets/T3584d547/unwanted-keychain-dialog.png)
- [Expected Shiori password prompt](assets/T3584d547/expected-shiori-password-dialog.png)
