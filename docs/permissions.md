# Permissions

Copy on Select requires two macOS privacy permissions. macOS shows the background
process as `copyonselectd` in System Settings. The process runs from
`~/Library/Application Support/CopyOnSelect/copyonselectd`.

The Raycast extension itself requires no privacy permission.

## Accessibility

### What it allows

Accessibility permission allows the process to inspect the focused user-interface
element of the frontmost application. It also allows the process to post a synthetic
key event.

### Why the process needs it

The process reads the role and the subrole of the focused element. That metadata
identifies a secure text field. The process rejects every secure text field before a
copy attempt. The process also reads the length of the current text selection. A length
of zero cancels the gesture.

The process posts the synthetic `Command-C` through the same permission. No other
mechanism posts a system-wide key event.

The process reads metadata only. The process never requests the value of a field.

### How to grant it

1. Open `System Settings`.
2. Select `Privacy & Security`.
3. Select `Accessibility`.
4. Find `copyonselectd` in the list.
5. Turn the switch on.
6. Enter the password of the Mac if macOS asks for it.
7. Run `Toggle Copy on Select` in Raycast.

If `copyonselectd` is absent from the list, run `Toggle Copy on Select` one time. The
first run creates the process and adds the entry.

### How to revoke it

1. Open `System Settings`.
2. Select `Privacy & Security`.
3. Select `Accessibility`.
4. Find `copyonselectd` in the list.
5. Turn the switch off.

After a revocation, the process removes the event tap and turns the behavior off. The
next Raycast command reports `Setup Required`.

## Input Monitoring

### What it allows

Input Monitoring permission allows the process to observe mouse events across all
applications.

### Why the process needs it

The process observes left-mouse button events and mouse movement. Those events drive
the gesture classification. A drag across a movement threshold becomes a selection
candidate. A double-click or a triple-click becomes a selection candidate.

The event tap is listen-only. The tap passes every event through unchanged. The tap
exists only while the behavior is on. Off means that the tap is absent, not that the
callbacks are ignored.

The process observes mouse events only. The process does not observe the keyboard.

### How to grant it

1. Open `System Settings`.
2. Select `Privacy & Security`.
3. Select `Input Monitoring`.
4. Find `copyonselectd` in the list.
5. Turn the switch on.
6. Enter the password of the Mac if macOS asks for it.
7. Run `Toggle Copy on Select` in Raycast.

### How to revoke it

1. Open `System Settings`.
2. Select `Privacy & Security`.
3. Select `Input Monitoring`.
4. Find `copyonselectd` in the list.
5. Turn the switch off.

## Screen Recording is not required

The product does not require Screen Recording permission. The product never captures
the screen. The product never reads pixels. The product reads Accessibility metadata
only.

If macOS asks for Screen Recording for `copyonselectd`, deny the request and open an
issue at <https://github.com/m-ghalib/raycast-copy-on-select/issues>.

## Recovery after a macOS update

A macOS update sometimes resets privacy permissions. The symptom is a
`Setup Required` result from a Raycast command that worked before the update.

1. Run `Toggle Copy on Select` in Raycast.
2. Read the reported error.
3. Open `System Settings` and select `Privacy & Security`.
4. Select `Accessibility`.
5. If `copyonselectd` is present and off, turn the switch on.
6. If `copyonselectd` is present and on, turn the switch off and then on again.
7. Select `Input Monitoring` and repeat steps 5 and 6.
8. Quit the background process:

   ```bash
   pkill -f copyonselectd
   ```

9. Run `Toggle Copy on Select` in Raycast.
10. Verify that Raycast reports `Copy on Select: On`.

If the list holds a stale entry for `copyonselectd`, remove the entry and add it again.

1. Select the `copyonselectd` row.
2. Select the minus button to remove the row.
3. Run `pkill -f copyonselectd` in a terminal.
4. Run `Toggle Copy on Select` in Raycast.
5. Grant the permission again when macOS asks.

## Verify the current permission state

Run the self test of the background process:

```bash
~/Library/Application\ Support/CopyOnSelect/copyonselectd --selftest
```

The command prints one JSON line and exits:

```json
{"ax":true,"inputMonitoring":true,"tap":true}
```

A value of `false` for `ax` means that Accessibility is absent. A value of `false` for
`inputMonitoring` means that Input Monitoring is absent. A value of `false` for `tap`
means that the process cannot create the event tap.

## Related documents

- [Installation](installation.md)
- [Troubleshooting](troubleshooting.md)
- [Privacy](../PRIVACY.md)
