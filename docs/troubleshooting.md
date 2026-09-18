# Troubleshooting

This document covers the known failure modes of Copy on Select. The background process
is `copyonselectd`. The process runs from
`~/Library/Application Support/CopyOnSelect/copyonselectd`.

## Symptom table

| Symptom | Cause | Fix |
|---|---|---|
| Raycast reports `Setup Required`. | Accessibility or Input Monitoring is absent. | Grant both permissions. Read [permissions.md](permissions.md). |
| Raycast reports that the background process is missing. | The extension files are incomplete or the checksum verification failed. | Reinstall the extension. Read the procedure below. |
| Raycast reports a timeout. | The process stopped, or the control socket is stale. | Run `pkill -f copyonselectd`. Run the command again. |
| Nothing copies in one application. | The application exposes no usable selection metadata. | Read [compatibility.md](compatibility.md). The product fails closed. |
| Nothing copies anywhere, and the state is `On`. | macOS disabled the event tap after an update. | Toggle off, toggle on. If that fails, follow the macOS update procedure below. |
| The wrong text reached the clipboard. | The selection changed before the copy, or another tool writes the clipboard. | Read the procedure below. |
| A copy occurs after an ordinary click. | A pointer movement crossed the drag threshold. | Report the case with the application name and the gesture. |
| No copy occurs in a password field. | Expected behavior. The product rejects secure text fields. | No action. |
| The behavior is off after a restart. | The process does not start at login. | Press the Raycast hotkey one time. The state restores. |
| Two toggles produce one state change. | Rapid repeated invocation. | Wait for the Raycast result before the next invocation. |

## Verify that the process runs

Run this command in a terminal:

```bash
pgrep -fl copyonselectd
```

A process identifier and a path appear when the process runs. Empty output means that
the process is not running. Empty output is normal after a restart and before the first
Raycast command.

## Verify the permission state

Run the self test:

```bash
~/Library/Application\ Support/CopyOnSelect/copyonselectd --selftest
```

The command prints one JSON line:

```json
{"ax":true,"inputMonitoring":true,"tap":true}
```

Every value must be `true`. A `false` value names the absent capability.

## The Raycast command reports an absent background process

The extension did not find the bundled binary, or the checksum did not match.

1. Open Raycast.
2. Open `Extensions` in the settings window.
3. Remove the `Copy on Select` extension.
4. Install the extension again.
5. Run `Toggle Copy on Select`.
6. If the error stays, and the extension came from a local build, run
   `./scripts/build.sh` again.
7. Verify that `raycast-extension/assets/copyonselectd` exists.
8. Verify that `raycast-extension/assets/copyonselectd.sha256` exists.
9. Run `cd raycast-extension && npm run build` to refresh the production build.
10. Import the extension again in Raycast. Development mode does not need to remain
    running.

## The toggle reports Setup Required

1. Run the self test. Read the section above.
2. Note every field with the value `false`.
3. Open `System Settings` and select `Privacy & Security`.
4. Grant the absent permission to `copyonselectd`. Read [permissions.md](permissions.md).
5. Run `pkill -f copyonselectd` in a terminal.
6. Run `Toggle Copy on Select` in Raycast.
7. Verify that Raycast reports `Copy on Select: On`.

## Nothing copies in a specific application

1. Verify that Raycast reports `Copy on Select: On`.
2. Open TextEdit and repeat the same gesture there.
3. If the copy works in TextEdit, the target application is the cause.
4. Select text in the target application and press `Command-C` by hand.
5. If the manual `Command-C` fails, the application uses a non-standard copy command.
   The product cannot support that application.
6. If the manual `Command-C` works, the application exposes no usable Accessibility
   selection metadata. The product fails closed and skips the copy.
7. Read [compatibility.md](compatibility.md).
8. Report the application name and the macOS version at
   <https://github.com/m-ghalib/raycast-copy-on-select/issues>.

## The wrong text reached the clipboard

1. Turn the behavior off with the Raycast hotkey.
2. Verify that no other clipboard tool writes the clipboard.
3. Turn the behavior on again.
4. Repeat the gesture and wait for the mouse-up event before a window switch.
5. If the wrong text returns, record the application, the gesture, and the order of the
   actions.
6. Report the case at <https://github.com/m-ghalib/raycast-copy-on-select/issues>.

Do not include the copied text in the report if the text is sensitive. Reproduce the
case with non-sensitive text first.

## The product stopped after a macOS update

A macOS update sometimes resets privacy permissions.

1. Run the self test. Read the section above.
2. Open `System Settings` and select `Privacy & Security`.
3. Select `Accessibility` and turn `copyonselectd` off and then on again.
4. Select `Input Monitoring` and turn `copyonselectd` off and then on again.
5. Run `pkill -f copyonselectd` in a terminal.
6. Run `Toggle Copy on Select` in Raycast.
7. If the error stays, remove the `copyonselectd` rows from both lists.
8. Run `Toggle Copy on Select` again and grant both permissions when macOS asks.

## Read the log

The log holds content-free diagnostics only. It holds no selected text and no clipboard
contents.

To read the whole log, run:

```bash
cat ~/Library/Application\ Support/CopyOnSelect/copyonselect.log
```

To watch new entries during a test, run:

```bash
tail -f ~/Library/Application\ Support/CopyOnSelect/copyonselect.log
```

To read the persisted state, run:

```bash
cat ~/Library/Application\ Support/CopyOnSelect/state.json
```

The state file looks like this:

```json
{"enabled":true,"schema":1,"version":"1.0.0"}
```

Attach the log to a bug report. Read the log first and remove anything unexpected.

## Restart the background process

```bash
pkill -f copyonselectd
```

Then run `Toggle Copy on Select` in Raycast. The command starts the process again and
restores the saved state.

## Related documents

- [Permissions](permissions.md)
- [Compatibility](compatibility.md)
- [Uninstall](uninstall.md)
