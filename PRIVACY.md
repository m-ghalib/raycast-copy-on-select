# Privacy

This statement describes the data behavior of Copy on Select version `1.0.0`. The
statement covers the Raycast extension and the bundled background process
`copyonselectd`.

## Summary

The product never reads the selected text. The product never reads the clipboard. The
product makes no network request. All data stays on the Mac of the user, inside one
directory.

## How the copy happens

The background process observes the completion of a left-mouse selection gesture. The
process then asks the macOS Accessibility API two questions. The first question is
whether the focused element is a secure text field. The second question is whether a
non-empty text selection exists.

Both questions use metadata. A range length answers the second question. The process
does not request the value of the selection.

If the gesture qualifies, the process posts one synthetic `Command-C` to the active
application. The target application then runs its own copy command. The target
application writes the clipboard content. The product never touches the pasteboard.

## What the product stores

The background process writes two files.

| File | Contents |
|---|---|
| `~/Library/Application Support/CopyOnSelect/state.json` | The enabled state, the schema version, and the binary version. |
| `~/Library/Application Support/CopyOnSelect/copyonselect.log` | Bounded content-free diagnostics. |

The directory also holds a copy of the `copyonselectd` binary and a Unix domain control
socket named `control.sock`. The socket carries one toggle request and one state
response. The socket carries no text content.

## What the log file contains

The log file holds only these fields.

- Timestamps.
- State transitions between on and off.
- Permission state for Accessibility and Input Monitoring.
- Coarse gesture classification, such as `drag` or `double-click`.
- Non-content error codes.
- The binary version.

The log file is bounded by a size limit. Old entries rotate out.

## What the log file must never contain

- Selected text.
- Clipboard contents.
- Typed characters.
- Secure-field values.
- Window titles, document names, or URLs.
- A history of application usage.

## Network

The product makes no network request. The product contains no analytics, no telemetry,
no crash reporter, no account system, and no update client. The product works offline.

## Where the data lives

All product data lives in one directory:

```text
~/Library/Application Support/CopyOnSelect/
├── copyonselectd          the background process binary
├── control.sock           the local control socket
├── copyonselect.log       bounded content-free diagnostics
└── state.json             the persisted on/off state
```

To read the stored state, run:

```bash
cat ~/Library/Application\ Support/CopyOnSelect/state.json
```

To read the diagnostics, run:

```bash
cat ~/Library/Application\ Support/CopyOnSelect/copyonselect.log
```

To remove all product data, follow [docs/uninstall.md](docs/uninstall.md).

## Source transparency

The source of `copyonselectd` is in the `macos-helper/` directory of this repository.
The script `scripts/build.sh` reproduces the bundled binary. The extension verifies the
SHA-256 checksum of the bundled binary before every start.

## Contact

To report a privacy concern, open an issue at
<https://github.com/m-ghalib/raycast-copy-on-select/issues>. To report a vulnerability,
follow [SECURITY.md](SECURITY.md) instead.
