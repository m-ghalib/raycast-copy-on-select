# Copy on Select

Copy on Select copies text to the clipboard right after a mouse text selection. One
Raycast command turns the behavior on and off.

Repository: <https://github.com/m-ghalib/raycast-copy-on-select>

## Status

The current version is `1.0.0`. Raycast Store review is not complete. The extension
bundles an open-source native binary and verifies the SHA-256 checksum of that binary
before every start. A local build produces a different binary. macOS keys privacy
permission to the exact binary. Therefore a user who builds from source must grant
Accessibility and Input Monitoring to that local build.

## What the product does

While the behavior is on, a supported mouse selection triggers the normal copy command
of the target application. The user selects text with a drag, a double-click, or a
triple-click. The selected text arrives on the clipboard without a `Command-C`
keystroke. While the behavior is off, nothing observes the mouse.

The product never reads the selected text. It posts a synthetic `Command-C` to the
active application. The target application produces the clipboard content, exactly as
it does for a physical key press.

A double-click and a triple-click arrive as a burst of separate clicks. The product waits
for the end of the burst. One gesture therefore produces one copy.

The product also suppresses a repeat of the selection that it copied last, so repeated
clicks do not fill the clipboard history. A copy from another source clears that
suppression. The comparison uses the character range of the selection and the pasteboard
change counter. It reads no clipboard content and no selected text.

## Architecture

The product has two parts inside one Raycast extension.

1. A no-view Raycast command named `Toggle Copy on Select`.
2. A small background process named `copyonselectd`.

A Raycast command runs only while Raycast executes it. The Raycast runtime ends the
command as soon as the command returns. Continuous mouse observation requires a process
that stays alive between commands. The extension therefore starts `copyonselectd` in
the background. That process owns the on/off state, the mouse event tap, the secure-field
verification, and the synthetic `Command-C`.

On the first toggle, the extension copies `copyonselectd` from its own `assets`
directory to `~/Library/Application Support/CopyOnSelect/copyonselectd`. The runtime
path is fixed for a reason. macOS attaches Accessibility and Input Monitoring permission
to the exact path and signature of a binary. A Raycast extension directory changes on
every extension update. A fixed path outside the extension directory keeps both
permissions valid across updates. The user grants permission one time.

There is no login item. The background process does not start at login. The saved on/off
state persists. The next use of the Raycast command restarts the process and restores
that state.

## Install

Install the Raycast extension. There is no separate application, no disk image, and no
download from a release page.

For the full procedure, read [docs/installation.md](docs/installation.md).

## Permissions

The background process requires two macOS permissions.

| Permission | Purpose |
|---|---|
| Accessibility | Inspect the focused element, reject secure text fields, and post the synthetic `Command-C`. |
| Input Monitoring | Observe left-mouse selection gestures while the behavior is on. |

The product does not require Screen Recording. macOS shows the process as
`copyonselectd` in System Settings.

For the full procedure, read [docs/permissions.md](docs/permissions.md).

## Privacy

The product never reads, stores, or transmits the selected text or the clipboard
contents. The product makes no network request. All data stays in
`~/Library/Application Support/CopyOnSelect/`.

For the full statement, read [PRIVACY.md](PRIVACY.md).

## Requirements

| Item | Value |
|---|---|
| Operating system | macOS 13.0 or later |
| Architecture | Apple silicon (`arm64`) and Intel (`x86_64`) |
| Raycast | A version with support for no-view commands |

## Repository layout

| Path | Contents |
|---|---|
| `macos-helper/` | Swift package source for the `copyonselectd` binary. |
| `raycast-extension/` | Raycast extension source and the bundled binary in `assets/`. |
| `scripts/build.sh` | Builds the universal binary and writes the SHA-256 file. |
| `docs/` | This documentation. |

## Build from source

1. Clone the repository.
2. Open a terminal in the repository root.
3. Run the unit tests:

   ```bash
   cd macos-helper && swift test
   ```

4. Build the universal binary and the checksum file:

   ```bash
   ./scripts/build.sh
   ```

5. Verify that `scripts/build.sh` wrote `raycast-extension/assets/copyonselectd` and
   `raycast-extension/assets/copyonselectd.sha256`.
6. In Raycast, run `Import Extension` and select the `raycast-extension` directory.
7. Grant Accessibility and Input Monitoring to the local build.

## Known limits

- Keyboard selections do not trigger a copy. Examples are `Shift-Arrow` and `Command-A`.
- Shift-click range extension does not trigger a copy.
- The product never pastes. It only copies.
- The product is not a clipboard manager. It keeps no history and no search.
- An application without usable Accessibility selection metadata fails closed. No copy
  occurs in that application.
- A selection that is not text does not trigger a copy. Examples are images, files, and
  canvas objects.

## Documentation

- [Installation](docs/installation.md)
- [Permissions](docs/permissions.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Uninstall](docs/uninstall.md)
- [Compatibility](docs/compatibility.md)
- [QA matrix](docs/qa-matrix.md)
- [Privacy](PRIVACY.md)
- [Security](SECURITY.md)
- [License](LICENSE)

## License

MIT. Copyright (c) 2026 Momin Abrar Ghalib. Read [LICENSE](LICENSE).
