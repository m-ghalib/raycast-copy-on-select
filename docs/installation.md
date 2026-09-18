# Installation

Copy on Select installs as one ordinary Raycast extension. There is no separate
application. There is no disk image. There is no download from a release page.

## Requirements

| Item | Value |
|---|---|
| Operating system | macOS 13.0 or later |
| Architecture | Apple silicon (`arm64`) or Intel (`x86_64`) |
| Raycast | A version with support for no-view commands |
| Administrator rights | Not required |

## Install the extension

1. Open Raycast.
2. Search the Raycast Store for `Copy on Select`.
3. Install the extension.
4. Run the command `Toggle Copy on Select` one time.
5. Read the result. Raycast reports `Setup Required` on the first run.
6. Grant Accessibility permission. Follow [permissions.md](permissions.md).
7. Grant Input Monitoring permission. Follow [permissions.md](permissions.md).
8. Run `Toggle Copy on Select` again.
9. Verify that Raycast reports `Copy on Select: On`.

## Assign a shortcut

1. In Raycast, open `Extensions` in the settings window.
2. Select the `Copy on Select` extension.
3. Select the command `Toggle Copy on Select`.
4. Set a hotkey in the `Hotkey` field.
5. Close the settings window.
6. Press the hotkey.
7. Verify that Raycast reports `Copy on Select: Off`.
8. Press the hotkey again to return to `Copy on Select: On`.

## Test the behavior

Do not test with a password, a token, or any other secret. A test writes the selected
text to the clipboard.

1. Open TextEdit.
2. Type the words `hello world`.
3. Turn the behavior on with the hotkey.
4. Drag across the word `hello`.
5. Release the mouse button.
6. Press `Command-V` in a new line.
7. Verify that the word `hello` appears.
8. Turn the behavior off with the hotkey.

## What happens on the first toggle

The first toggle starts a background process. The extension copies the bundled binary
`copyonselectd` to `~/Library/Application Support/CopyOnSelect/copyonselectd` and starts
it. The extension verifies the SHA-256 checksum of the bundled binary before the copy.

The runtime path is fixed and outside the extension directory. macOS attaches privacy
permission to the exact path of a binary. A Raycast extension directory changes on every
extension update. The fixed path keeps the Accessibility and Input Monitoring grants
valid across updates.

The background process does not start at login. The saved on/off state persists. The
next use of the Raycast command restarts the process and restores that state.

## Build from source

Use this procedure to build the binary and to load the extension without the Raycast
Store.

1. Install Xcode and the Swift toolchain.
2. Clone the repository:

   ```bash
   git clone https://github.com/m-ghalib/raycast-copy-on-select.git
   ```

3. Run the unit tests:

   ```bash
   cd raycast-copy-on-select/macos-helper && swift test
   ```

4. Return to the repository root.
5. Build the universal binary and the checksum file:

   ```bash
   ./scripts/build.sh
   ```

6. Verify that the script wrote `raycast-extension/assets/copyonselectd` and
   `raycast-extension/assets/copyonselectd.sha256`.
7. Build the production Raycast extension:

   ```bash
   cd raycast-extension
   npm install
   npm run build
   ```

8. In Raycast, run the command `Import Extension`.
9. Select the `raycast-extension` directory.
10. Run `Toggle Copy on Select` one time.
11. Grant Accessibility and Input Monitoring to the local build.

`npm run dev` is only for live development. After the production build is imported,
the command continues to work when development mode is not running.

A local build produces a different binary. macOS treats a different binary as a
different program. Therefore the user must grant both permissions again after a local
build.

## Safety notes

Do not disable Gatekeeper. Do not remove quarantine attributes. Do not run a remote
install script with elevated rights. This product does not require any of those actions.

## Next steps

- [Permissions](permissions.md)
- [Troubleshooting](troubleshooting.md)
- [Uninstall](uninstall.md)
