{
  "id": "3584d547",
  "title": "Avoid blocking keychain dialog on first Safari share",
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

On the first run of the macOS share extension from Safari, an unwanted system Keychain authorization dialog appears over the extension’s Loading screen. It says “Save to Shiori (Safari) wants to use your confidential information stored in ‘net.emberson.shiorishare’ in your keychain” and asks for the login keychain password.

The user cannot enter anything into that system dialog. Pressing Escape dismisses it and allows the extension to proceed to its own “Enter Password” screen. The user can then enter the Shiori password, and it is saved successfully.

Steps to reproduce:
1. Run the share extension from Safari for the first time.
2. Observe the system Keychain authorization dialog; its password field does not accept input.
3. Press Escape.
4. Enter the Shiori password in the extension’s own password screen and continue; the password is saved.

Expected: The first-run flow reaches the extension’s Shiori password prompt without a blocking, unusable system Keychain dialog. Subsequent use can access the saved password normally.

Reported after installing macOS version 0.4.0. Root cause has not been investigated.

Screenshots supplied by the user:
- tmp/Unwanted permission dialog.png — blocking system Keychain dialog (Image #1).
- tmp/Expected permsisson dialog.png — usable Shiori password prompt after Escape (Image #2; filename spelling preserved).

Screenshots archived with this issue:
- [Unwanted system Keychain dialog](assets/T3584d547/unwanted-keychain-dialog.png)
- [Expected Shiori password prompt](assets/T3584d547/expected-shiori-password-dialog.png)
