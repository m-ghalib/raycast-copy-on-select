# Uninstall

This procedure removes Copy on Select and all of its data. The procedure needs no
administrator rights.

## Before the procedure

The procedure deletes `~/Library/Application Support/CopyOnSelect/`. That directory
holds the saved on/off state and the diagnostic log. The deletion is permanent.

## Procedure

### 1. Turn the behavior off

1. Press the Raycast hotkey for `Toggle Copy on Select`.
2. Verify that Raycast reports `Copy on Select: Off`.

### 2. Quit the background process

Run this command in a terminal:

```bash
pkill -f copyonselectd
```

An exit code of `1` means that no process matched. That result is normal when the
process already stopped.

### 3. Remove the extension from Raycast

1. Open Raycast.
2. Open `Extensions` in the settings window.
3. Find `Copy on Select`.
4. Remove the extension.

### 4. Delete the support directory

Run this command in a terminal:

```bash
rm -rf ~/Library/Application\ Support/CopyOnSelect
```

This command deletes the binary copy, the control socket, the state file, and the log
file. The command removes the last product data on the Mac.

### 5. Remove the permission entries

1. Open `System Settings`.
2. Select `Privacy & Security`.
3. Select `Accessibility`.
4. Select the `copyonselectd` row.
5. Select the minus button.
6. Return to `Privacy & Security`.
7. Select `Input Monitoring`.
8. Select the `copyonselectd` row.
9. Select the minus button.

### 6. Verify the removal

Run these commands in a terminal:

```bash
pgrep -fl copyonselectd
ls ~/Library/Application\ Support/CopyOnSelect
```

The first command must print nothing. Empty output means that no process remains.

The second command must print `No such file or directory`. That message means that no
product data remains.

Open `System Settings` and verify that `copyonselectd` is absent from the Accessibility
list and from the Input Monitoring list.

## Login items

The product registers no login item. No further cleanup is required.

## Remove a source build

If a clone of the repository exists, delete the clone directory. The clone holds the
build output and the extension source.

## Related documents

- [Installation](installation.md)
- [Permissions](permissions.md)
- [Privacy](../PRIVACY.md)
